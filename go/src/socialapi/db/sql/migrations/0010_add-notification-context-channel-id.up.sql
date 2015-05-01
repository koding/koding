-- With Team Product we need to have seperate notifications for each group.
-- For this reason we have added context_channel_id column
CREATE OR REPLACE FUNCTION get_koding_group_channel() RETURNS BIGINT AS $$
DECLARE koding_channel_id BIGINT;

BEGIN
  SELECT into koding_channel_id (SELECT id FROM api.channel WHERE type_constant = 'group' AND group_name = 'koding' LIMIT 1);
  RETURN koding_channel_id;
END;
$$ LANGUAGE plpgsql;

DO $$
  BEGIN
    DECLARE koding_channel_id BIGINT := get_koding_group_channel();
    BEGIN
      IF koding_channel_id IS NULL THEN
        EXECUTE 'ALTER TABLE notification.notification ADD COLUMN context_channel_id BIGINT NOT NULL';
      ELSE
        EXECUTE 'ALTER TABLE notification.notification ADD COLUMN context_channel_id BIGINT NOT NULL DEFAULT ' || koding_channel_id;
      END IF;
      EXCEPTION
        WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;

