-- ----------------------------------------------------------------------------------------
--  Structure for table File
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table file
-- ----------------------------
ALTER TABLE sitemap.file ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table file
-- ----------------------------
ALTER TABLE sitemap.file ADD CONSTRAINT "file_name_key" UNIQUE ("name") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table file
-- ----------------------------
CREATE UNIQUE INDEX  "sitemap_id_key" ON sitemap.file USING btree(id ASC NULLS LAST);