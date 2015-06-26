DROP INDEX IF EXISTS payment.customer_old_id_idx;
CREATE INDEX customer_old_id_idx ON payment.customer (old_id);
