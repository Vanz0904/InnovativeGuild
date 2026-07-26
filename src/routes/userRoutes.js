const express = require('express');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

function publicUser(user) {
  return {
    id: user.id,
    fullName: user.full_name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    isVerified: !!user.is_verified,
    trustScore: user.trust_score,
    twoFactorEnabled: !!user.two_factor_enabled,
    createdAt: user.created_at,
  };
}

// GET /api/users/me
router.get('/me', requireAuth, async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [req.user.id]);
  if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
  res.json({ user: publicUser(rows[0]) });
});

// PUT /api/users/me — update editable profile fields + toggles
router.put('/me', requireAuth, async (req, res) => {
  const { fullName, phone, twoFactorEnabled } = req.body;
  await pool.query(
    `UPDATE users SET
       full_name = COALESCE(?, full_name),
       phone = COALESCE(?, phone),
       two_factor_enabled = COALESCE(?, two_factor_enabled)
     WHERE id = ?`,
    [fullName ?? null, phone ?? null, twoFactorEnabled === undefined ? null : (twoFactorEnabled ? 1 : 0), req.user.id]
  );
  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [req.user.id]);
  res.json({ user: publicUser(rows[0]) });
});

// GET /api/users/search?q=&role=seller — used when a buyer creates an escrow
router.get('/search', requireAuth, async (req, res) => {
  const { q = '', role = 'seller' } = req.query;
  const [rows] = await pool.query(
    `SELECT id, full_name, email, phone, trust_score, is_verified
     FROM users
     WHERE role = ? AND is_suspended = 0 AND (email LIKE ? OR phone LIKE ? OR full_name LIKE ?)
     LIMIT 10`,
    [role, `%${q}%`, `%${q}%`, `%${q}%`]
  );
  res.json({
    users: rows.map((u) => ({
      id: u.id,
      fullName: u.full_name,
      email: u.email,
      phone: u.phone,
      trustScore: u.trust_score,
      isVerified: !!u.is_verified,
    })),
  });
});

module.exports = router;
