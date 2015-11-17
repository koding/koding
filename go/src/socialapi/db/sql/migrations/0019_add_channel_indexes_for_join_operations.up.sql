DO $$
  BEGIN
    BEGIN
      CREATE INDEX "channel_deleted_at_group_name_type_constant_creator_id_idx" ON "api"."channel" USING btree (deleted_at ASC NULLS FIRST, group_name DESC NULLS FIRST, type_constant DESC NULLS FIRST, creator_id DESC NULLS FIRST);
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'channel_deleted_at_group_name_type_constant_creator_id_idx already exists';
    END;

    BEGIN
      CREATE INDEX "channel_group_name_type_constant_deleted_at_idx" ON "api"."channel" USING btree (group_name DESC NULLS FIRST, type_constant DESC NULLS FIRST, deleted_at DESC NULLS FIRST);
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'channel_group_name_type_constant_deleted_at_idx already exists';
    END;

  END;
$$;
