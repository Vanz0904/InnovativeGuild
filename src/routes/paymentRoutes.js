const express = require('express');
const pool = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { notify } = require('../utils/notify');
const { verifyTransaction, verifyByReference } = require('../utils/flutterwave');

const router = express.Router();

/**
 * GET /api/payments/config
 * Gives the Flutter app the public key + redirect info it needs to
 * open the Flutterwave Standard checkout. Never expose FLW_SECRET_KEY
 * here — only the public key is safe for the client.
 */
router.get('/config', requireAuth, (req, res) => {
  res.json({
    publicKey: process.env.FLW_PUBLIC_KEY,
    currency: 'MWK',
    paymentOptions: 'card,mobilemoneymalawi,banktransfer',
  });
});

/**
 * POST /api/payments/initiate
 * Buyer is about to pay for a pending_payment transaction. We return
 * a unique tx_ref for the Flutterwave client SDK to use, along with
 * the amount/currency/customer info it needs — the actual charge UI
 * is rendered by flutterwave_standard on the Flutter side.
 */
router.post('/initiate', requireAuth, requireRole('buyer'), async (req, res) => {
  const { transactionReference } = req.body;

  const [rows] = await pool.query(
    `SELECT t.*, b.full_name AS buyer_name, b.email AS buyer_email, b.phone AS buyer_phone
     FROM transactions t JOIN users b ON b.id = t.buyer_id WHERE t.reference = ?`,
    [transactionReference]
  );
  if (rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
  const tx = rows[0];

  if (tx.buyer_id !== req.user.id) return res.status(403).json({ error: 'Not your transaction' });
  if (tx.status !== 'pending_payment') {
    return res.status(400).json({ error: 'This transaction is not awaiting payment' });
  }

  const flwTxRef = `SG-PAY-${tx.id}-${Date.now()}`;
  const totalAmount = Number(tx.amount) + Number(tx.fee);

  await pool.query(
    `INSERT INTO payment_events (transaction_id, provider, flw_tx_ref, status, amount)
     VALUES (?, 'flutterwave', ?, 'initiated', ?)`,
    [tx.id, flwTxRef, totalAmount]
  );

  res.json({
    txRef: flwTxRef,
    amount: totalAmount,
    currency: tx.currency,
    customer: { email: tx.buyer_email, name: tx.buyer_name, phoneNumber: tx.buyer_phone },
    narration: `SafeGuard escrow — ${tx.title}`,
  });
});

/**
 * POST /api/payments/verify
 * Called by the Flutter app right after the Flutterwave checkout
 * callback fires. We independently re-verify with Flutterwave's
 * server API before trusting anything the client told us — this is
 * the critical anti-fraud step for a payment gateway integration.
 */
router.post('/verify', requireAuth, requireRole('buyer'), async (req, res) => {
  const { transactionReference, flwTransactionId, txRef } = req.body;
  if (!flwTransactionId && !txRef) {
    return res.status(400).json({ error: 'Missing Flutterwave transaction id or reference' });
  }

  const [rows] = await pool.query('SELECT * FROM transactions WHERE reference = ?', [transactionReference]);
  if (rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
  const tx = rows[0];

  if (tx.buyer_id !== req.user.id) return res.status(403).json({ error: 'Not your transaction' });

  try {
    const verification = flwTransactionId
      ? await verifyTransaction(flwTransactionId)
      : await verifyByReference(txRef);
    const data = verification?.data;
    const expectedAmount = Number(tx.amount) + Number(tx.fee);

    const isValid =
      verification.status === 'success' &&
      data?.status === 'successful' &&
      Number(data?.amount) >= expectedAmount &&
      data?.currency === tx.currency;

    await pool.query(
      `INSERT INTO payment_events (transaction_id, provider, flw_transaction_id, status, amount, raw_payload)
       VALUES (?, 'flutterwave', ?, ?, ?, ?)`,
      [tx.id, data?.id || flwTransactionId || null, data?.status || 'unknown', data?.amount || null, JSON.stringify(data || {})]
    );

    if (!isValid) {
      return res.status(400).json({ error: 'Payment could not be verified. Please contact support before retrying.' });
    }

    await pool.query(
      `UPDATE transactions SET status = 'payment_held', payment_method = ?, payment_reference = ? WHERE id = ?`,
      [data.payment_type || 'flutterwave', String(data?.id || flwTransactionId || txRef), tx.id]
    );

    await notify(tx.seller_id, {
      type: 'payment',
      title: 'Payment secured in escrow',
      message: `${tx.currency} ${expectedAmount} for "${tx.title}" is now held by SafeGuard. Confirm the order to ship it.`,
      transactionId: tx.id,
    });
    await notify(tx.buyer_id, {
      type: 'payment',
      title: 'Payment secured',
      message: `Your payment for "${tx.title}" is safely locked in escrow.`,
      transactionId: tx.id,
    });

    res.json({ success: true, status: 'payment_held' });
  } catch (err) {
    console.error(err?.response?.data || err);
    res.status(502).json({ error: 'Could not reach Flutterwave to verify this payment' });
  }
});

/**
 * POST /api/payments/webhook
 * Flutterwave server-to-server webhook — a more reliable confirmation
 * path than relying solely on the client callback. Validates the
 * verif-hash header against FLW_SECRET_HASH before trusting anything.
 * Configure this URL in the Flutterwave dashboard under Webhooks.
 */
router.post('/webhook', express.json(), async (req, res) => {
  const signature = req.headers['verif-hash'];
  if (!signature || signature !== process.env.FLW_SECRET_HASH) {
    return res.status(401).end();
  }

  const payload = req.body;
  const flwTransactionId = payload?.data?.id;

  if (payload?.event === 'charge.completed' && flwTransactionId) {
    try {
      const verification = await verifyTransaction(flwTransactionId);
      const data = verification?.data;
      if (data?.status === 'successful') {
        const txRef = data.tx_ref || '';
        const match = txRef.match(/SG-PAY-(\d+)-/);
        if (match) {
          const transactionId = match[1];
          const [rows] = await pool.query('SELECT * FROM transactions WHERE id = ?', [transactionId]);
          if (rows.length && rows[0].status === 'pending_payment') {
            await pool.query(
              `UPDATE transactions SET status = 'payment_held', payment_method = ?, payment_reference = ? WHERE id = ?`,
              [data.payment_type || 'flutterwave', String(flwTransactionId), transactionId]
            );
            await notify(rows[0].seller_id, {
              type: 'payment',
              title: 'Payment secured in escrow',
              message: `Payment for "${rows[0].title}" was confirmed via webhook and is now held by SafeGuard.`,
              transactionId,
            });
          }
        }
      }
    } catch (err) {
      console.error('Webhook verification failed:', err?.response?.data || err);
    }
  }

  res.status(200).end();
});

module.exports = router;
