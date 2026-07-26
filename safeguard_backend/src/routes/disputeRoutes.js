const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { notify } = require('../utils/notify');

const router = express.Router();

function shapeDispute(row) {
  return {
    id: `DP-${row.id}`,
    transactionId: row.transaction_reference,
    reason: row.reason,
    description: row.description,
    stage: row.stage,
    resolution: row.resolution,
    filedAt: row.created_at,
    resolvedAt: row.resolved_at,
  };
}

const SELECT_DISPUTE = `
  SELECT d.*, t.reference AS transaction_reference, t.title AS transaction_title,
         t.buyer_id, t.seller_id, t.amount, t.currency
  FROM disputes d
  JOIN transactions t ON t.id = d.transaction_id
`;

// POST /api/disputes — buyer or seller files a dispute on a transaction
router.post(
  '/',
  requireAuth,
  [body('transactionReference').notEmpty(), body('reason').notEmpty()],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ error: errors.array()[0].msg });

    const { transactionReference, reason, description } = req.body;

    const [txRows] = await pool.query('SELECT * FROM transactions WHERE reference = ?', [transactionReference]);
    if (txRows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
    const tx = txRows[0];

    if (tx.buyer_id !== req.user.id && tx.seller_id !== req.user.id) {
      return res.status(403).json({ error: 'Not your transaction' });
    }
    if (tx.status === 'completed' || tx.status === 'refunded') {
      return res.status(400).json({ error: 'This transaction is already closed and cannot be disputed' });
    }

    const [result] = await pool.query(
      `INSERT INTO disputes (transaction_id, filed_by, reason, description) VALUES (?, ?, ?, ?)`,
      [tx.id, req.user.id, reason, description || null]
    );
    await pool.query("UPDATE transactions SET status = 'disputed' WHERE id = ?", [tx.id]);

    const otherParty = tx.buyer_id === req.user.id ? tx.seller_id : tx.buyer_id;
    await notify(otherParty, {
      type: 'dispute',
      title: 'A dispute was filed',
      message: `A dispute was opened on "${tx.title}" (${tx.reference}). Our resolution team will review shortly.`,
      transactionId: tx.id,
    });

    // Notify all admins so the case appears in their queue immediately.
    const [admins] = await pool.query("SELECT id FROM users WHERE role = 'admin'");
    for (const admin of admins) {
      await notify(admin.id, {
        type: 'dispute',
        title: 'New dispute filed',
        message: `${reason} — ${tx.reference} (${tx.title})`,
        transactionId: tx.id,
      });
    }

    const [rows] = await pool.query(`${SELECT_DISPUTE} WHERE d.id = ?`, [result.insertId]);
    res.status(201).json({ dispute: shapeDispute(rows[0]) });
  }
);

// GET /api/disputes/mine
router.get('/mine', requireAuth, async (req, res) => {
  const [rows] = await pool.query(
    `${SELECT_DISPUTE} WHERE t.buyer_id = ? OR t.seller_id = ? ORDER BY d.created_at DESC`,
    [req.user.id, req.user.id]
  );
  res.json({ disputes: rows.map(shapeDispute) });
});

// GET /api/disputes/:transactionReference — case tracker for one transaction
router.get('/:transactionReference', requireAuth, async (req, res) => {
  const [rows] = await pool.query(`${SELECT_DISPUTE} WHERE t.reference = ? ORDER BY d.created_at DESC LIMIT 1`, [
    req.params.transactionReference,
  ]);
  if (rows.length === 0) return res.status(404).json({ error: 'No dispute found for this transaction' });
  res.json({ dispute: shapeDispute(rows[0]) });
});

// PUT /api/disputes/:id/stage — admin moves a case through review stages
router.put('/:id/stage', requireAuth, requireRole('admin'), async (req, res) => {
  const { stage } = req.body;
  const valid = ['filed', 'under_review', 'evidence_requested', 'mediation', 'resolved'];
  if (!valid.includes(stage)) return res.status(400).json({ error: 'Invalid stage' });

  await pool.query('UPDATE disputes SET stage = ? WHERE id = ?', [stage, req.params.id]);
  const [rows] = await pool.query(`${SELECT_DISPUTE} WHERE d.id = ?`, [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ error: 'Dispute not found' });

  const d = rows[0];
  const partyId = d.buyer_id; // notify buyer of stage change; seller gets one too below
  await notify(partyId, {
    type: 'dispute',
    title: 'Dispute update',
    message: `Your case for ${d.transaction_reference} moved to "${stage.replace('_', ' ')}".`,
    transactionId: d.transaction_id,
  });
  await notify(d.seller_id, {
    type: 'dispute',
    title: 'Dispute update',
    message: `The dispute on ${d.transaction_reference} moved to "${stage.replace('_', ' ')}".`,
    transactionId: d.transaction_id,
  });

  res.json({ dispute: shapeDispute(d) });
});

/**
 * POST /api/disputes/:id/resolve — admin's final ruling.
 * resolution: 'refund_buyer' | 'release_seller' | 'partial'
 */
router.post('/:id/resolve', requireAuth, requireRole('admin'), async (req, res) => {
  const { resolution, notes } = req.body;
  if (!['refund_buyer', 'release_seller', 'partial'].includes(resolution)) {
    return res.status(400).json({ error: 'Invalid resolution' });
  }

  const [rows] = await pool.query(`${SELECT_DISPUTE} WHERE d.id = ?`, [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ error: 'Dispute not found' });
  const d = rows[0];

  await pool.query(
    `UPDATE disputes SET stage = 'resolved', resolution = ?, resolution_notes = ?, resolved_at = NOW() WHERE id = ?`,
    [resolution, notes || null, d.id]
  );

  const newTxStatus = resolution === 'refund_buyer' ? 'refunded' : 'completed';
  await pool.query('UPDATE transactions SET status = ? WHERE id = ?', [newTxStatus, d.transaction_id]);

  const outcomeText =
    resolution === 'refund_buyer'
      ? `${d.currency} ${d.amount} was refunded to the buyer.`
      : resolution === 'release_seller'
      ? `${d.currency} ${d.amount} was released to the seller.`
      : 'Funds were split between both parties as a partial settlement.';

  await notify(d.buyer_id, {
    type: 'dispute',
    title: 'Dispute resolved',
    message: `Case for ${d.transaction_reference} is resolved. ${outcomeText}`,
    transactionId: d.transaction_id,
  });
  await notify(d.seller_id, {
    type: 'dispute',
    title: 'Dispute resolved',
    message: `Case for ${d.transaction_reference} is resolved. ${outcomeText}`,
    transactionId: d.transaction_id,
  });

  const [updated] = await pool.query(`${SELECT_DISPUTE} WHERE d.id = ?`, [d.id]);
  res.json({ dispute: shapeDispute(updated[0]) });
});

module.exports = router;
