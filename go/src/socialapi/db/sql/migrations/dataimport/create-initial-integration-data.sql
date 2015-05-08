
-- CREATE ITERABLE INTEGRATION
INSERT INTO integration.integration (name, title, type_constant)
VALUES ('iterable','Iterable', 'incoming');

-- CREATE KODING CHANNEL ITERABLE INTEGRATION
CREATE OR REPLACE FUNCTION get_iterable_integration () RETURNS BIGINT AS $$
DECLARE iterable_integration_id BIGINT ;
BEGIN
	SELECT
		INTO iterable_integration_id (
			SELECT
				ID
			FROM
				integration.integration
			WHERE
				name = 'iterable'
			LIMIT 1
		) ;
	RETURN iterable_integration_id ;
END ;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_creator_id () RETURNS BIGINT AS $$
DECLARE creator_id BIGINT ;
BEGIN
	SELECT
		INTO creator_id (
			SELECT
				ID
			FROM
				api.account
			WHERE
				nick = 'devrim'
			LIMIT 1
		) ;
	RETURN creator_id ;
END ;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_koding_group_channel () RETURNS BIGINT AS $$
DECLARE koding_channel_id BIGINT;

BEGIN
  SELECT into koding_channel_id (SELECT id FROM api.channel WHERE type_constant = 'group' AND group_name = 'koding' LIMIT 1);
  RETURN koding_channel_id;
END;
$$ LANGUAGE plpgsql;



DO $$
	BEGIN
		DECLARE iterable_integration_id BIGINT := get_iterable_integration ();
		DECLARE creator_id BIGINT := get_creator_id ();
		DECLARE koding_channel_id BIGINT := get_koding_group_channel ();
		BEGIN
			INSERT INTO integration.channel_integration (
				integration_id,
				token,
				group_name,
				creator_id,
				channel_id,
				is_disabled
			)
			VALUES (iterable_integration_id, uuid_generate_v4(), 'koding', creator_id, koding_channel_id, FALSE);
		END;
	END;
$$;

