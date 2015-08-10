--kill the membership schema, tables, and functions
drop schema if exists membership CASCADE;

--good to use a schema to keep your tables, views, functions
--organized and confined
create schema membership;

--set this so what we create here will be applied to the membership schema
set search_path=membership;

--global functions
create or replace function random_value(len int, out result varchar(32))
  as
$$
BEGIN
SELECT substr( encode(membership.gen_random_bytes(len /2 +1), 'hex'), 1, len ) into result;
END
$$ LANGUAGE plpgsql;

--a scalable id generator that works like snowflake
--http://rob.conery.io/2014/05/29/a-better-id-generator-for-postgresql/
CREATE OR REPLACE FUNCTION id_generator(OUT result bigint) AS $$
DECLARE
  our_epoch bigint := 1314220021721;
  seq_id bigint;
  now_millis bigint;
  shard_id int := 1;
  BEGIN
    SELECT nextval('membership.membership_id_seq')%1024 INTO seq_id;

    SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
    result := (now_millis - our_epoch) << 23;
    result := result | (shard_id << 10);
    result := result | (seq_id);
  END;
$$ LANGUAGE PLPGSQL;

--sequence for id generator
create sequence membership_id_seq;

--log enum, change as needed
create type log_type as ENUM('registration', 'authentication', 'activity', 'system');

-- for our member lookup bits
create type member_summary as (
  id bigint,
  email varchar(255),
  status varchar(50),
  can_login bool,
  is_admin bool,
  first varchar(25),
  last varchar(25),
  member_key varchar(12),
  email_validation_token varchar(36),
  created_at timestamptz,
  signin_count int,
  social json,
  location json,
  logs json,
  notes json,
  roles json

);

--drop in pgcrypto if it's not there
create extension if not exists pgcrypto with schema membership;

select 'DB Initialized' as result;
