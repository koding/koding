
-- ----------------------------
--  Structure for table PaymentsCustomer
-- ----------------------------
-- ----------------------------
--  Primary key structure for table customer
-- ----------------------------
ALTER TABLE payment.customer ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table customer
-- ----------------------------
ALTER TABLE payment.customer ADD CONSTRAINT "customer_provider_customer_id_provider_key" UNIQUE ("provider_customer_id", "provider") NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE payment.customer ADD CONSTRAINT "customer_old_id_key" UNIQUE ("old_id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Structure for table PaymentsPlan
-- ----------------------------
-- ----------------------------
--  Primary key structure for table plan
-- ----------------------------
ALTER TABLE payment.plan ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table plan
-- ----------------------------
ALTER TABLE payment.plan ADD CONSTRAINT "plan_provider_plan_id_provider_key" UNIQUE ("provider_plan_id", "provider") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Structure for table PaymentSubscription
-- ----------------------------
-- ----------------------------
--  Primary key structure for table subscription
-- ----------------------------
ALTER TABLE payment.subscription ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table subscription
-- ----------------------------
ALTER TABLE payment.subscription ADD CONSTRAINT "subscription_provider_subscription_id_provider_key" UNIQUE ("provider_subscription_id", "provider") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table message_subscription
-- ----------------------------
ALTER TABLE payment.subscription ADD CONSTRAINT "plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES payment.plan (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE payment.subscription ADD CONSTRAINT "customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES payment.customer (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
