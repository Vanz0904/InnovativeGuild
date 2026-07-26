/**
 * Creates (or updates) the one default administrator account.
 * Admins are NEVER created through the public /api/auth/register
 * endpoint — this seed script is the only way an admin account
 * comes into existence, matching the product requirement that
 * admin access is provisioned by SafeGuard, not self-registered.
 *
 * Usage: npm run seed
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../src/config/db');

async function seed() {
  const email = process.env.DEFAULT_ADMIN_EMAIL || 'admin@safeguard.mw';
  const password = process.env.DEFAULT_ADMIN_PASSWORD || 'SafeGuard@2026';
  const name = process.env.DEFAULT_ADMIN_NAME || 'SafeGuard Administrator';

  const passwordHash = await bcrypt.hash(password, 10);

  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);

  if (existing.length > 0) {
    await pool.query(
      'UPDATE users SET password_hash = ?, role = ?, is_verified = 1 WHERE email = ?',
      [passwordHash, 'admin', email]
    );
    console.log(`✔ Existing admin account updated: ${email}`);
  } else {
    await pool.query(
      `INSERT INTO users (full_name, email, phone, password_hash, role, is_verified, trust_score)
       VALUES (?, ?, ?, ?, 'admin', 1, 100)`,
      [name, email, '+265000000000', passwordHash]
    );
    console.log(`✔ Default admin account created: ${email}`);
  }

  console.log('  Password: (as set in your .env DEFAULT_ADMIN_PASSWORD)');
  console.log('  ⚠ Log in and change this password immediately in production.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
