--
-- Clear previously created database
--
DROP DATABASE IF EXISTS "tinder_db";
--
-- Create database itself
--
CREATE DATABASE "tinder_db" OWNER "tinder_role" ENCODING 'UTF8'  TEMPLATE template0;