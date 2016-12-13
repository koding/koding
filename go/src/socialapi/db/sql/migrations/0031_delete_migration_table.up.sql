Select 1 from pg_tables;
-- WARNING:
-- dont run this on production with migration
-- DELETE FROM "api"."interaction";
-- DELETE FROM "api"."message_reply";
-- DELETE FROM "api"."channel_link";
-- DELETE FROM "api"."channel_participant"   USING "api"."channel" WHERE "api"."channel_participant".channel_id = "api"."channel".id     AND "api"."channel".type_constant <> 'collaboration' AND "api"."channel".type_constant <> 'group';
-- DELETE FROM "api"."channel_message_list"  USING "api"."channel" WHERE "api"."channel_message_list".channel_id = "api"."channel".id    AND "api"."channel".type_constant <> 'collaboration';
-- DELETE FROM "api"."channel_message"       USING "api"."channel" WHERE "api"."channel_message".initial_channel_id = "api"."channel".id AND "api"."channel".type_constant <> 'collaboration';
-- DELETE FROM "api"."channel"                                     WHERE "api"."channel".type_constant <> 'collaboration' AND "api"."channel".type_constant <> 'group';
