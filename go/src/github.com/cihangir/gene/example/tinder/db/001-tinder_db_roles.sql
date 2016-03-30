--
-- Create Parent Role
--
DROP ROLE IF EXISTS "tinder_role";
CREATE ROLE "tinder_role";
--
-- Create shadow user for future extensibility
--
DROP USER IF EXISTS "tinder_roleapplication";
CREATE USER "tinder_roleapplication" PASSWORD 'tinder_roleapplication';
--
-- Convert our application user to parent
--
GRANT "tinder_role" TO "tinder_roleapplication";