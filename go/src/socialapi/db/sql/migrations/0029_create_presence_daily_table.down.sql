DROP INDEX IF EXISTS "presence"."presence_daily_crea_at_acc_id_group_name_is_proc_idx";
DROP TABLE IF EXISTS "presence"."daily";

DROP SEQUENCE "presence"."daily_id_seq";

--
-- drop schema
--
DO $$
  BEGIN
    BEGIN
      DROP SCHEMA presence;
    END;
  END;
$$;
