CREATE USER paymentro PASSWORD '8QRzgCHJb2u4zyTtX';
GRANT usage ON SCHEMA payment to paymentro;

-- ----------------------------
--  Only grant access to previously create tables.
-- ----------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA payment TO paymentro;
