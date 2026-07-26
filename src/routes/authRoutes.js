const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const pool = require('../config/db');
const { notify } = require('../utils/notify');

const router = express.Router();

function signToken(user) {
  return jwt.sign(
    { id: user.id, role: user.role, email: user.email, fullName: user.full_name },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

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
  };
}

/**
 * POST /api/auth/register
 * Public registration only ever creates 'buyer' or 'seller' accounts.
 * Any 'admin' value in the request body is ignored — admins can only
 * be provisioned via database/seed.js, never through this endpoint.
 */
router.post(
  '/register',
  [
    body('fullName').trim().notEmpty().withMessage('Full name is required'),
    body('email').isEmail().withMessage('A valid email is required'),
    body('phone').trim().notEmpty().withMessage('Phone number is required'),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('role').isIn(['buyer', 'seller']).withMessage('Role must be buyer or seller'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    const { fullName, email, phone, password, role } = req.body;

    try {
      const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
      if (existing.length > 0) {
        return res.status(409).json({ error: 'An account with this email already exists' });
      }

      const passwordHash = await bcrypt.hash(password, 10);

      const [result] = await pool.query(
        `INSERT INTO users (full_name, email, phone, password_hash, role, trust_score)
         VALUES (?, ?, ?, ?, ?, 70)`,
        [fullName, email, phone, passwordHash, role]
      );

      const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [result.insertId]);
      const user = rows[0];

      await notify(user.id, {
        type: 'security',
        title: 'Welcome to SafeGuard',
        message: `Your ${role} account has been created. Complete identity verification to unlock higher transaction limits.`,
      });

      return res.status(201).json({ token: signToken(user), user: publicUser(user) });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ error: 'Registration failed. Please try again.' });
    }
  }
);

/**
 * POST /api/auth/login
 * Works for all roles (buyer, seller, admin) — the client decides
 * which screen to route to based on the returned user.role. The admin
 * login screen additionally rejects a successful login if role !== 'admin'.
 */
router.post(
  '/login',
  [body('email').isEmail(), body('password').notEmpty()],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'A valid email and password are required' });
    }

    const { email, password } = req.body;

    try {
      const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
      if (rows.length === 0) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const user = rows[0];

      if (user.is_suspended) {
        return res.status(403).json({ error: 'This account has been suspended. Contact support.' });
      }

      const match = await bcrypt.compare(password, user.password_hash);
      if (!match) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      await notify(user.id, {
        type: 'security',
        title: 'New sign-in detected',
        message: 'Your SafeGuard account was just signed into. If this wasn\'t you, reset your password immediately.',
      });

      return res.json({ token: signToken(user), user: publicUser(user) });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ error: 'Login failed. Please try again.' });
    }
  }
);

module.exports = router;
