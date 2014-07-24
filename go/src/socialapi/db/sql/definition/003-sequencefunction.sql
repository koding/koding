-- SET ROLE social;
-- ----------------------------
--  Functions for Channel
-- ----------------------------
CREATE OR REPLACE FUNCTION api.channel_next_id(OUT result bigint) AS $$
DECLARE
    seq_id bigint;
    now_millis bigint;
    shard_id int := 0;
BEGIN
    SELECT mod(nextval('api.channel_id_seq'),1024) INTO seq_id;

    SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
    result := (now_millis) << 22;
    result := result | (shard_id << 10);
    result := result | (seq_id);
END;
$$ LANGUAGE PLPGSQL;
REVOKE ALL ON FUNCTION api.channel_next_id(OUT result bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION api.channel_next_id(OUT result bigint) TO "social";

-- ----------------------------
--  Functions for Channel Message Table
-- ----------------------------
CREATE OR REPLACE FUNCTION api.channel_message_next_id(OUT result bigint) AS $$
DECLARE
    seq_id bigint;
    now_millis bigint;
    shard_id int := 0;
BEGIN
    SELECT mod(nextval('api.channel_message_id_seq'),1024) INTO seq_id;

    SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
    result := (now_millis) << 22;
    result := result | (shard_id << 10);
    result := result | (seq_id);
END;
$$ LANGUAGE PLPGSQL;
REVOKE ALL ON FUNCTION api.channel_message_next_id(OUT result bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION api.channel_message_next_id(OUT result bigint) TO "social";

