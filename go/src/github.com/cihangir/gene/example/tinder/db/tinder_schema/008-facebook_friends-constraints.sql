-------------------------------
--  Primary key structure for table facebook_friends
-- ----------------------------
ALTER TABLE "tinder_schema"."facebook_friends" ADD PRIMARY KEY ("source_id, target_id") NOT DEFERRABLE INITIALLY IMMEDIATE;