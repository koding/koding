DO $$
  BEGIN
    BEGIN
      CREATE INDEX  "notification_account_id_context_id_notification_content_id_idx" ON "notification"."notification" USING btree(account_id DESC, context_channel_id DESC, notification_content_id DESC);
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'notification_account_id_context_id_notification_content_id_idx already exists';
    END;

    BEGIN
      CREATE INDEX  "notification_activity_actor_id_content_id_obsolete_idx" ON "notification"."notification_activity" USING btree(actor_id DESC, notification_content_id DESC, obsolete);
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'notification_activity_actor_id_content_id_obsolete_idx already exists';
    END;

    BEGIN
      CREATE INDEX  "notification_content_type_constant_target_id_idx" ON "notification"."notification_content" USING btree(type_constant DESC, target_id DESC);
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'notification_content_type_constant_target_id_idx already exists';
    END;

  END;
$$;
