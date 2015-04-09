-- drop the constraint
ALTER TABLE api.account DROP CONSTRAINT "account_token_key";

-- drop the column first
ALTER TABLE api.account DROP COLUMN token;
