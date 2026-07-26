-- SafeGuard escrow platform — MySQL schema
-- Run with: mysql -u root -p < database/schema.sql

CREATE DATABASE IF NOT EXISTS safeguard CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE safeguard;

-- ============================================================
-- USERS — buyers, sellers, and admins all live in one table,
-- differentiated by `role`. Admins are never created through the
-- public registration endpoint (enforced in src/routes/authRoutes.js);
-- the only admin account comes from database/seed.js.
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(30) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('buyer', 'seller', 'admin') NOT NULL DEFAULT 'buyer',
  is_verified TINYINT(1) NOT NULL DEFAULT 0,
  is_suspended TINYINT(1) NOT NULL DEFAULT 0,
  trust_score INT NOT NULL DEFAULT 80,
  two_factor_enabled TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- TRANSACTIONS — the core escrow record between a buyer and seller.
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  reference VARCHAR(30) NOT NULL UNIQUE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  category VARCHAR(60) DEFAULT 'Other',
  amount DECIMAL(14,2) NOT NULL,
  fee DECIMAL(14,2) NOT NULL,
  currency VARCHAR(6) NOT NULL DEFAULT 'MWK',
  buyer_id INT NOT NULL,
  seller_id INT NOT NULL,
  status ENUM(
    'pending_payment',
    'payment_held',
    'seller_confirmed',
    'in_transit',
    'delivery_verification',
    'completed',
    'disputed',
    'refunded'
  ) NOT NULL DEFAULT 'pending_payment',
  delivery_address VARCHAR(255),
  courier VARCHAR(80),
  tracking_code VARCHAR(60),
  estimated_delivery DATE,
  payment_method VARCHAR(40),
  payment_reference VARCHAR(120),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (buyer_id) REFERENCES users(id),
  FOREIGN KEY (seller_id) REFERENCES users(id),
  INDEX idx_buyer (buyer_id),
  INDEX idx_seller (seller_id),
  INDEX idx_status (status)
) ENGINE=InnoDB;

-- ============================================================
-- DISPUTES
-- ============================================================
CREATE TABLE IF NOT EXISTS disputes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id INT NOT NULL,
  filed_by INT NOT NULL,
  reason VARCHAR(120) NOT NULL,
  description TEXT,
  stage ENUM('filed', 'under_review', 'evidence_requested', 'mediation', 'resolved') NOT NULL DEFAULT 'filed',
  resolution ENUM('pending', 'refund_buyer', 'release_seller', 'partial') NOT NULL DEFAULT 'pending',
  resolution_notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  FOREIGN KEY (filed_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('security', 'payment', 'delivery', 'dispute', 'system') NOT NULL DEFAULT 'system',
  title VARCHAR(150) NOT NULL,
  message VARCHAR(500) NOT NULL,
  related_transaction_id INT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_user_read (user_id, is_read)
) ENGINE=InnoDB;

-- ============================================================
-- PAYMENT EVENTS — audit trail of every Flutterwave interaction
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id INT NOT NULL,
  provider VARCHAR(30) NOT NULL DEFAULT 'flutterwave',
  flw_tx_ref VARCHAR(120),
  flw_transaction_id VARCHAR(120),
  status VARCHAR(40),
  amount DECIMAL(14,2),
  raw_payload JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
) ENGINE=InnoDB;
