const express = require('express');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function shapeNotification(row) {
  return {
    id: `N-${row.id}`,
    type: row.type,
    title: row.title,
    message: row.message,
    time: row.created_at,
    isRead: !!row.is_read,
    transactionId: row.related_transaction_id,
  };
}

// GET /api/notifications
router.get('/', requireAuth, async (req, res) => {
  const [rows] = await pool.query(
    'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
    [req.user.id]
  );
  res.json({ notifications: rows.map(shapeNotification) });
});

// GET /api/notifications/unread-count
router.get('/unread-count', requireAuth, async (req, res) => {
  const [rows] = await pool.query(
    'SELECT COUNT(*) AS count FROM notifications WHERE user_id = ? AND is_read = 0',
    [req.user.id]
  );
  res.json({ count: rows[0].count });
});

// POST /api/notifications/:id/read
router.post('/:id/read', requireAuth, async (req, res) => {
  const numericId = req.params.id.replace('N-', '');
  await pool.query('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?', [numericId, req.user.id]);
  res.json({ success: true });
});

// POST /api/notifications/read-all
router.post('/read-all', requireAuth, async (req, res) => {
  await pool.query('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [req.user.id]);
  res.json({ success: true });
});

module.exports = router;
