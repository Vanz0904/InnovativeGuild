const axios = require('axios');
require('dotenv').config();

const flw = axios.create({
  baseURL: process.env.FLW_BASE_URL || 'https://api.flutterwave.com/v3',
  headers: {
    Authorization: `Bearer ${process.env.FLW_SECRET_KEY}`,
    'Content-Type': 'application/json',
  },
});

/**
 * Verifies a completed Flutterwave transaction by its Flutterwave
 * transaction ID. This is the server-side check that must pass before
 * we ever mark an escrow transaction's payment as held — never trust
 * the client's "payment succeeded" callback alone.
 *
 * Docs: https://developer.flutterwave.com/docs/verifying-transactions
 */
async function verifyTransaction(flwTransactionId) {
  const { data } = await flw.get(`/transactions/${flwTransactionId}/verify`);
  return data; // { status, data: { status, amount, currency, tx_ref, ... } }
}

/**
 * Optional: query Flutterwave by our own tx_ref instead of their ID,
 * useful if the webhook arrives before the client redirect does.
 */
async function verifyByReference(txRef) {
  const { data } = await flw.get('/transactions/verify_by_reference', {
    params: { tx_ref: txRef },
  });
  return data;
}

module.exports = { verifyTransaction, verifyByReference };
