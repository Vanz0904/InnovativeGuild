const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { notify } = require('../utils/notify');

const router = express.Router();

function generateReference() {
  const rand = Math.floor(10000 + Math.random() * 89999);
  return `SG-${rand}`;
}

/** Shapes a raw DB row + counterparty info into the JSON the Flutter app expects. */
function shapeTransaction(row, myId) {
  const isBuyer = row.buyer_id === myId;
  return {
    id: row.reference,
    dbId: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    amount: row.amount,
    fee: row.fee,
    currency: row.currency,
    status: row.status,
    myRole: isBuyer ? 'buyer' : 'seller',
    counterpartyName: isBuyer ? row.seller_name : row.buyer_name,
    counterpartyInitials: (isBuyer ? row.seller_name : row.buyer_name)
      .split(' ')
      .map((s) => s[0])
      .join('')
      .slice(0, 2)
      .toUpperCase(),
    deliveryAddress: row.delivery_address,
    courier: row.courier,
    trackingCode: row.tracking_code,
    estimatedDelivery: row.estimated_delivery,
    paymentMethod: row.payment_method,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

const SELECT_WITH_NAMES = `
  SELECT t.*, b.full_name AS buyer_name, s.full_name AS seller_name
  FROM transactions t
  JOIN users b ON b.id = t.buyer_id
  JOIN users s ON s.id = t.seller_id
`;

/**
 * POST /api/transactions
 * A buyer creates a new escrow transaction against a seller they've
 * looked up via /api/users/search. Status starts at pending_payment
 * until Flutterwave confirms funds (see paymentRoutes.js).
 */
router.post(
  '/',
  requireAuth,
  requireRole('buyer'),
  [
    body('title').trim().notEmpty(),
    body('sellerId').isInt(),
    body('amount').isFloat({ gt: 0 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    const { title, description, category, sellerId, amount, deliveryAddress } = req.body;
    const feeRate = parseFloat(process.env.ESCROW_FEE_RATE || '0.02');
    const fee = Math.round(amount * feeRate * 100) / 100;

    try {
      const [sellerRows] = await pool.query("SELECT id FROM users WHERE id = ? AND role = 'seller'", [sellerId]);
      if (sellerRows.length === 0) {
        return res.status(404).json({ error: 'Seller not found' });
      }

      const reference = generateReference();

      const [result] = await pool.query(
        `INSERT INTO transactions
          (reference, title, description, category, amount, fee, buyer_id, seller_id, delivery_address, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending_payment')`,
        [reference, title, description || null, category || 'Other', amount, fee, req.user.id, sellerId, deliveryAddress || null]
      );

      const [rows] = await pool.query(`${SELECT_WITH_NAMES} WHERE t.id = ?`, [result.insertId]);
      res.status(201).json({ transaction: shapeTransaction(rows[0], req.user.id) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Could not create escrow transaction' });
    }
  }
);

// GET /api/transactions/mine — everything where I'm the buyer or the seller
router.get('/mine', requireAuth, async (req, res) => {
  const { status } = req.query;
  let sql = `${SELECT_WITH_NAMES} WHERE (t.buyer_id = ? OR t.seller_id = ?)`;
  const params = [req.user.id, req.user.id];

  if (status) {
    sql += ' AND t.status = ?';
    params.push(status);
  }
  sql += ' ORDER BY t.created_at DESC';

  const [rows] = await pool.query(sql, params);
  res.json({ transactions: rows.map((r) => shapeTransaction(r, req.user.id)) });
});

// GET /api/transactions/:reference
router.get('/:reference', requireAuth, async (req, res) => {
  const [rows] = await pool.query(`${SELECT_WITH_NAMES} WHERE t.reference = ?`, [req.params.reference]);
  if (rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });

  const row = rows[0];
  if (row.buyer_id !== req.user.id && row.seller_id !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'You do not have access to this transaction' });
  }
  res.json({ transaction: shapeTransaction(row, req.user.id) });
});

/**
 * POST /api/transactions/:reference/confirm-shipment
 * Seller confirms the order and provides shipment info. Only valid
 * once payment is actually held (fraud-prevention: a seller shouldn't
 * even see "confirm & ship" until money is secured — the UI enforces
 * this too, but the API is the real gate).
 */
router.post(
  '/:reference/confirm-shipment',
  requireAuth,
  requireRole('seller'),
  [body('courier').notEmpty(), body('trackingCode').notEmpty()],
  async (req, res) => {
    const { courier, trackingCode, estimatedDelivery } = req.body;

    const [rows] = await pool.query(`${SELECT_WITH_NAMES} WHERE t.reference = ?`, [req.params.reference]);
    if (rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
    const tx = rows[0];

    if (tx.seller_id !== req.user.id) return res.status(403).json({ error: 'Not your transaction' });
    if (tx.status !== 'payment_held') {
      return res.status(400).json({ error: 'Payment must be held in escrow before you can confirm shipment' });
    }

    await pool.query(
      `UPDATE transactions SET status = 'seller_confirmed', courier = ?, tracking_code = ?, estimated_delivery = ?
       WHERE id = ?`,
      [courier, trackingCode, estimatedDelivery || null, tx.id]
    );

    await notify(tx.buyer_id, {
      type: 'delivery',
      title: 'Your order has shipped',
      message: `${tx.seller_name} confirmed "${tx.title}" and shipped it via ${courier}. Tracking: ${trackingCode}.`,
      transactionId: tx.id,
    });

    const [updated] = await pool.query(`${SELECT_WITH_NAMES} WHERE t.id = ?`, [tx.id]);
    res.json({ transaction: shapeTransaction(updated[0], req.user.id) });
  }
);

/**
 * POST /api/transactions/:reference/release
 * Buyer verifies delivery and releases funds to the seller. This is
 * the moment escrow funds move from "held" to "completed" — in a
 * production system this would also trigger a real payout via
 * Flutterwave Transfers; that call is stubbed here (see comment).
 */
router.post('/:reference/release', requireAuth, requireRole('buyer'), async (req, res) => {
  const [rows] = await pool.query(`${SELECT_WITH_NAMES} WHERE t.reference = ?`, [req.params.reference]);
  if (rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
  const tx = rows[0];

  if (tx.buyer_id !== req.user.id) return res.status(403).json({ error: 'Not your transaction' });
  if (!['seller_confirmed', 'in_transit', 'delivery_verification'].includes(tx.status)) {
    return res.status(400).json({ error: 'This transaction is not ready for delivery confirmation' });
  }

  await pool.query("UPDATE transactions SET status = 'completed' WHERE id = ?", [tx.id]);

  // TODO (production): call Flutterwave Transfers API here to pay the
  // seller's linked bank/mobile-money account, then record a
  // payment_events row with the payout reference.

  await notify(tx.seller_id, {
    type: 'payment',
    title: 'Funds released to you',
    message: `${tx.buyer_name} confirmed delivery of "${tx.title}". ${tx.currency} ${tx.amount} has been released to you.`,
    transactionId: tx.id,
  });

  const [updated] = await pool.query(`${SELECT_WITH_NAMES} WHERE t.id = ?`, [tx.id]);
  res.json({ transaction: shapeTransaction(updated[0], req.user.id) });
});

module.exports = router;
