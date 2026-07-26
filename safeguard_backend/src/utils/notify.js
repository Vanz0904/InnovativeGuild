const pool = require('../config/db');

/**
 * Inserts a notification for a user. Called by transaction, dispute,
 * and payment routes whenever something happens that the user should
 * know about. The Flutter app polls GET /api/notifications, so a row
 * written here is what "notifications working" means end-to-end.
 */
async function notify(userId, { type = 'system', title, message, transactionId = null }) {
  await pool.query(
    `INSERT INTO notifications (user_id, type, title, message, related_transaction_id)
     VALUES (?, ?, ?, ?, ?)`,
    [userId, type, title, message, transactionId]
  );
}

module.exports = { notify };
