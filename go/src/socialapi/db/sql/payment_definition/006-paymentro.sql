CREATE USER paymentro PASSWORD 'N8bG8ZVjp2y87Zxfi3';
GRANT usage ON SCHEMA payment to paymentro;

-- ----------------------------
--  Only grant access to previously create tables.
-- ----------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA payment TO paymentro;
