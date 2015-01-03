-- remove added type
-- postgres doesnt support removing a value from a type

-- remove added column 
ALTER TABLE "api"."channel" DROP COLUMN IF EXISTS "payload";
