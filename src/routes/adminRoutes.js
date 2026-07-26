const express = require('express');
const pool = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { notify } = require('../utils/notify');

const router = express.Router();
router.use(requireAuth, requireRole('admin'));

// GET /api/admin/stats — platform-wide numbers for the admin dashboard
router.get('/stats', async (req, res) => {
  const [[userCounts]] = await pool.query(
    `SELECT
       COUNT(*) AS total,
       SUM(role = 'buyer') AS buyers,
       SUM(role = 'seller') AS sellers,
       SUM(role = 'admin') AS admins
     FROM users`
  );

  const [[txCounts]] = await pool.query(
    `SELECT
       COUNT(*) AS total,
       COALESCE(SUM(CASE WHEN status IN ('payment_held','seller_confirmed','in_transit','delivery_verification') THEN amount ELSE 0 END), 0) AS held_volume,
       COALESCE(SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END), 0) AS completed_volume,
       SUM(status = 'completed') AS completed_count,
       SUM(status = 'disputed') AS disputed_count
     FROM transactions`
  );

  const [[disputeCounts]] = await pool.query(
    `SELECT COUNT(*) AS open_count FROM disputes WHERE stage != 'resolved'`
  );

  const [dailyVolume] = await pool.query(
    `SELECT DATE(created_at) AS day, COALESCE(SUM(amount), 0) AS volume
     FROM transactions
     WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
     GROUP BY DATE(created_at)
     ORDER BY day ASC`
  );

  res.json({
    users: {
      total: userCounts.total,
      buyers: userCounts.buyers || 0,
      sellers: userCounts.sellers || 0,
      admins: userCounts.admins || 0,
    },
    transactions: {
      total: txCounts.total,
      heldVolume: txCounts.held_volume,
      completedVolume: txCounts.completed_volume,
      completedCount: txCounts.completed_count || 0,
      disputedCount: txCounts.disputed_count || 0,
    },
    disputes: { open: disputeCounts.open_count || 0 },
    dailyVolume,
  });
});

// GET /api/admin/users
router.get('/users', async (req, res) => {
  const { role } = req.query;
  let sql = 'SELECT id, full_name, email, phone, role, is_verified, is_suspended, trust_score, created_at FROM users';
  const params = [];
  if (role) {
    sql += ' WHERE role = ?';
    params.push(role);
  }
  sql += ' ORDER BY created_at DESC LIMIT 200';
  const [rows] = await pool.query(sql, params);
  res.json({
    users: rows.map((u) => ({
      id: u.id,
      fullName: u.full_name,
      email: u.email,
      phone: u.phone,
      role: u.role,
      isVerified: !!u.is_verified,
      isSuspended: !!u.is_suspended,
      trustScore: u.trust_score,
      createdAt: u.created_at,
    })),
  });
});

// PUT /api/admin/users/:id/suspend — toggles suspension
router.put('/users/:id/suspend', async (req, res) => {
  const { suspended } = req.body;
  await pool.query('UPDATE users SET is_suspended = ? WHERE id = ?', [suspended ? 1 : 0, req.params.id]);
  await notify(req.params.id, {
    type: 'security',
    title: suspended ? 'Account suspended' : 'Account reinstated',
    message: suspended
      ? 'Your SafeGuard account has been suspended pending review. Contact support for details.'
      : 'Your SafeGuard account has been reinstated.',
  });
  res.json({ success: true });
});

// GET /api/admin/transactions — full platform transaction list
router.get('/transactions', async (req, res) => {
  const { status } = req.query;
  let sql = `
    SELECT t.*, b.full_name AS buyer_name, s.full_name AS seller_name
    FROM transactions t
    JOIN users b ON b.id = t.buyer_id
    JOIN users s ON s.id = t.seller_id`;
  const params = [];
  if (status) {
    sql += ' WHERE t.status = ?';
    params.push(status);
  }
  sql += ' ORDER BY t.created_at DESC LIMIT 200';
  const [rows] = await pool.query(sql, params);
  res.json({
    transactions: rows.map((t) => ({
      id: t.reference,
      title: t.title,
      amount: t.amount,
      currency: t.currency,
      status: t.status,
      buyerName: t.buyer_name,
      sellerName: t.seller_name,
      createdAt: t.created_at,
    })),
  });
});

// GET /api/admin/disputes — full dispute queue, optionally filtered by stage
router.get('/disputes', async (req, res) => {
  const { stage } = req.query;
  let sql = `
    SELECT d.*, t.reference AS transaction_reference, t.title AS transaction_title, t.amount, t.currency,
           b.full_name AS buyer_name, s.full_name AS seller_name
    FROM disputes d
    JOIN transactions t ON t.id = d.transaction_id
    JOIN users b ON b.id = t.buyer_id
    JOIN users s ON s.id = t.seller_id`;
  const params = [];
  if (stage) {
    sql += ' WHERE d.stage = ?';
    params.push(stage);
  }
  sql += ' ORDER BY d.created_at DESC';
  const [rows] = await pool.query(sql, params);
  res.json({
    disputes: rows.map((d) => ({
      id: `DP-${d.id}`,
      transactionId: d.transaction_reference,
      transactionTitle: d.transaction_title,
      amount: d.amount,
      currency: d.currency,
      reason: d.reason,
      stage: d.stage,
      resolution: d.resolution,
      buyerName: d.buyer_name,
      sellerName: d.seller_name,
      filedAt: d.created_at,
    })),
  });
});

module.exports = router;
