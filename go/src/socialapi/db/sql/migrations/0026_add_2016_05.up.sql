DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'socialapp_2016_05') THEN

      CREATE USER socialapp_2016_05 PASSWORD 'socialapp_2016_05';
   END IF;
END
$body$
;
GRANT social TO socialapp_2016_05;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'kontrolapp_2016_05') THEN

      CREATE USER kontrolapp_2016_05 PASSWORD 'kontrolapp_2016_05';
   END IF;
END
$body$
;

GRANT kontrol TO kontrolapp_2016_05;

ALTER USER paymentro with password 'paymentro';

-- replace with proper passwords
-- ALTER USER paymentro with password 'paymentro';
-- ALTER USER socialapp_2016_05 with password 'socialapp_2016_05';
-- ALTER USER kontrolapp_2016_05 with password 'kontrolapp_2016_05';
