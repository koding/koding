ALTER TABLE payment.customer ADD CONSTRAINT "customer_old_id_key" UNIQUE ("old_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
