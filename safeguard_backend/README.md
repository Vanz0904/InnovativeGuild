# SafeGuard Backend

Node.js + Express + MySQL API powering the SafeGuard escrow app, with
Flutterwave as the payment gateway.

## Setup

```bash
cd safeguard_backend
npm install
cp .env.example .env
# edit .env: set your MySQL credentials and Flutterwave test keys
```

Create the database and tables:

```bash
mysql -u root -p < database/schema.sql
```

Seed the one default administrator account (email/password come from
your `.env`):

```bash
npm run seed
```

Start the server:

```bash
npm run dev     # with nodemon, auto-restarts on changes
# or
npm start
```

The API listens on `http://localhost:4000` by default. Check it's up:

```bash
curl http://localhost:4000/api/health
```

## Flutterwave setup

1. Create a free account at https://dashboard.flutterwave.com
2. Grab your **Test** public/secret keys from Settings → API Keys
3. Paste them into `.env` as `FLW_PUBLIC_KEY` / `FLW_SECRET_KEY`
4. Under Settings → Webhooks, set your webhook URL to
   `https://<your-deployed-backend>/api/payments/webhook` and set a
   secret hash — put that same value in `.env` as `FLW_SECRET_HASH`
5. Use Flutterwave's test cards/mobile money numbers to simulate
   payments end-to-end: https://developer.flutterwave.com/docs/integration-guides/testing-helpers

The webhook won't reach `localhost` directly — use a tunnel like
`ngrok http 4000` during development and point the webhook at the
ngrok URL.

## Roles

- **buyer** / **seller** — created only through `POST /api/auth/register`
- **admin** — created only through `npm run seed`; there is no public
  endpoint that can create or promote an account to admin

## API summary

| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/api/auth/register` | — | Create a buyer or seller account |
| POST | `/api/auth/login` | — | Log in (any role) |
| GET | `/api/users/me` | any | Current profile |
| PUT | `/api/users/me` | any | Update profile / toggle 2FA |
| GET | `/api/users/search?q=&role=seller` | any | Find a seller to create escrow with |
| POST | `/api/transactions` | buyer | Create an escrow transaction |
| GET | `/api/transactions/mine` | any | My transactions (as buyer or seller) |
| GET | `/api/transactions/:reference` | any | Transaction detail |
| POST | `/api/transactions/:reference/confirm-shipment` | seller | Confirm order + add tracking |
| POST | `/api/transactions/:reference/release` | buyer | Verify delivery, release funds |
| POST | `/api/disputes` | any | File a dispute |
| GET | `/api/disputes/mine` | any | My disputes |
| GET | `/api/disputes/:transactionReference` | any | Case tracker |
| PUT | `/api/disputes/:id/stage` | admin | Move case through review stages |
| POST | `/api/disputes/:id/resolve` | admin | Final ruling (refund/release/partial) |
| GET | `/api/notifications` | any | My notifications |
| POST | `/api/notifications/:id/read` | any | Mark one as read |
| POST | `/api/notifications/read-all` | any | Mark all as read |
| GET | `/api/payments/config` | any | Flutterwave public key + options |
| POST | `/api/payments/initiate` | buyer | Get a tx_ref to open checkout with |
| POST | `/api/payments/verify` | buyer | Server-side verification after checkout |
| POST | `/api/payments/webhook` | Flutterwave | Server-to-server payment confirmation |
| GET | `/api/admin/stats` | admin | Platform-wide dashboard numbers |
| GET | `/api/admin/users` | admin | All users |
| PUT | `/api/admin/users/:id/suspend` | admin | Suspend/reinstate a user |
| GET | `/api/admin/transactions` | admin | All transactions |
| GET | `/api/admin/disputes` | admin | Full dispute queue |

## Notes

- This sandbox environment used to generate this code has no network
  access, so it could not run `npm install`, connect to a live MySQL
  instance, or call Flutterwave's API — the code above hasn't been
  executed end-to-end. Please run it locally and open an issue in your
  own tracker for anything that needs adjusting for your exact MySQL
  version or Flutterwave account setup.
- Production hardening still to add: rate limiting, refresh tokens,
  file storage for KYC documents (e.g. S3), real payouts via
  Flutterwave Transfers on `release`, and HTTPS termination.
