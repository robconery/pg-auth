-- built on Sat Mar 14 2015 19:32:30 GMT+0100 (CET)

BEGIN;

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
SELECT substring(md5(random()::text),0, len) into result;
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


create table logins (
    id bigint primary key not null unique DEFAULT id_generator(),
    member_id bigint not null,
    provider varchar(50) not null default 'local',
    provider_key varchar(255),
    provider_token varchar(255) not null
);

create table logs(
    id serial primary key not null,
    subject log_type,
    member_id bigint not null,
    entry text not null,
    data json,
    created_at timestamptz default current_timestamp
);

create table mailers(
    id serial primary key not null,
    name varchar(255) not null,
    from_address varchar(255),
    from_name varchar(255),
    subject varchar(255),
    template_markdown text
);

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('Welcome','noreply@site.com','Admin','Welcome to Our Site','Welcome to our site!');

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('password-reset','noreply@site.com','Admin','Password Reset Instructions','Welcome to our site!');

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('validation','noreply@site.com','Admin','Email Validation Request','Welcome to our site!');

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('general','noreply@site.com','Admin','Welcome to Our Site','Welcome to our site!');

create table members(
    id bigint primary key not null unique DEFAULT id_generator(),
    first varchar(25),
    last varchar(25),
    member_key varchar(12) not null unique default random_value(12),
    email_validation_token varchar(36) default random_value(36),
    reset_password_token varchar(36),
    reset_password_token_set_at timestamptz,
    email varchar(255) unique not null,
    search tsvector,
    created_at timestamptz DEFAULT current_timestamp,
    signin_count int,
    membership_status_id int not null,
    social json,
    location json
);

CREATE TRIGGER members_search_vector_refresh
BEFORE INSERT OR UPDATE ON members
FOR EACH ROW EXECUTE PROCEDURE
tsvector_update_trigger(search, 'pg_catalog.english',  email, first, last);



create table notes(
    id serial primary key not null,
    member_id bigint not null,
    note text not null,
    created_at timestamptz default current_timestamp
);

create table roles(
    id integer primary key not null,
    description varchar(24) not null
);

create table members_roles(
    member_id bigint not null,
    role_id int not null,
    primary key (member_id, role_id)
);

-- default roles
insert into membership.roles (id, description) values(10, 'Administrator');
insert into membership.roles (id, description) values(99, 'User');


create table sessions(
    id bigint primary key not null unique DEFAULT id_generator(),
    token varchar(24) not null unique default random_value(24),
    ip inet,
    member_id bigint not null,
    created_at timestamptz not null DEFAULT current_timestamp,
    expires_at timestamptz not null
);

create table settings(
    id serial primary key not null,
    allow_token_login boolean not null default true,
    lock_trigger int not null default 0,
    reset_password_within_hours int not null default 6,
    session_length_weeks int not null default 2,
    email_validation_required boolean not null default false,
    email_from_name varchar(50) not null,
    email_from_address varchar(125) not null
);

insert into membership.settings(email_from_name, email_from_address)
values ('Admin', 'admin@example.com');

create table status(
    id int  primary key not null,
    name varchar(50),
    description varchar(255),
    can_login boolean not null default true
);

-- default statuses
insert into membership.status(id, name, description) values(10, 'Active', 'User can login, etc');
insert into membership.status(id, name, description,can_login) values(20, 'Suspended','Cannot login for a given reason',false);
insert into membership.status(id, name, description,can_login) values(30, 'Not Approved','Member needs to be approved (email validation, etc)',false);
insert into membership.status(id, name, description,can_login) values(99, 'Banned','Member has been banned',false);
insert into membership.status(id, name, description,can_login) values(88, 'Locked', 'Member is locked out due to failed logins',false);

select 'tables installed' as result;

set search_path = membership;

ALTER TABLE logins 
ADD CONSTRAINT logins_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE logs 
ADD CONSTRAINT logs_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE notes 
ADD CONSTRAINT notes_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE members_roles 
ADD CONSTRAINT member_roles_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE members_roles 
ADD CONSTRAINT member_roles_roles
FOREIGN KEY (role_id) REFERENCES roles (id) on delete cascade;

ALTER TABLE sessions 
ADD CONSTRAINT sessions_members
FOREIGN KEY (member_id) REFERENCES members(id) on delete cascade;

create or replace function add_login(
    member_email varchar(255),
    key varchar(50),
    token varchar(255),
    new_provider varchar(50)
)
returns TABLE(
  message varchar(255),
  success boolean
) as
$$
DECLARE
success boolean;
message varchar(255);
found_id bigint;
data_result json;
BEGIN
  select false into success;
  select 'User not found with this email' into message;
  select id into found_id from membership.members where email = member_email;

  if found_id is not null then
    --replace the provider for this user completely
    delete from membership.logins where found_id = membership.logins.member_id AND membership.logins.provider = new_provider;

    --add the login
    insert into membership.logins(member_id,provider_key, provider_token, provider)
    values (found_id, key,token,new_provider);

    --add log entry
    insert into membership.logs(subject,entry,member_id, created_at)
    values('authentication','Added ' || new_provider || ' login',found_id,now());

    select true into success;
    select 'Added login successfully' into message;


  end if;

  return query
  select message, success;

END;
$$
language plpgsql;

create or replace function add_member_to_role(member_email varchar(255), new_role_id int, out succeeded bool)
as $$
DECLARE
found_member_id bigint;
selected_role varchar(50);
BEGIN
    select false into succeeded;
    if exists(select id from membership.members where email=member_email) then
        select id into found_member_id from membership.members where email=member_email;
        if not exists(select member_id from membership.members_roles where member_id = found_member_id and role_id=new_role_id) then
            insert into membership.members_roles(member_id, role_id) values (found_member_id, new_role_id);
            --add a log entry
            select description into selected_role from membership.roles where id=new_role_id;
            insert into membership.logs(subject,entry,member_id, created_at)
            values('registration','Member added to role ' || selected_role,found_member_id,now());
            select true into succeeded;
        end if;
    end if;
END;
$$ LANGUAGE plpgsql;

create or replace function add_note(member_email varchar(50), note_text varchar(512),out succeeded bool)
as $$
DECLARE
found_id bigint;
BEGIN
  select id into found_id from membership.members where email = member_email;
  select false into succeeded;
  if found_id is not null then

    insert into membership.notes(member_id, note)
    values(found_id, note_text);

    select true into succeeded;

  end if;
end;

$$ LANGUAGE PLPGSQL;

create or replace function authenticate(
    pkey varchar(255),
    ptoken varchar(255),
    prov varchar(50),
    ip inet
)
returns TABLE (
    member_id bigint,
    session_id bigint,
    message varchar(255),
    email varchar(255),
    success boolean,
    public_name varchar(255)
) as

$$
DECLARE
  return_id bigint;
  return_name varchar(255);
  new_session_id bigint;
  message varchar(255);
  success boolean;
  found_user membership.members;
  session_length int;
  member_can_login boolean;
  search_token varchar(255);
BEGIN

    --defaults
    select false into success;
    select 'Invalid username or password' into message;

    if prov = 'local' then
      -- find the user with a crypted password
      select membership.logins.member_id from membership.logins
      where membership.logins.provider_key=pkey
      AND membership.logins.provider_token = membership.crypt(ptoken,provider_token)
      AND membership.logins.provider=prov into return_id;
    else
      -- find the user with a token
      select membership.logins.member_id from membership.logins
      WHERE membership.logins.provider_token = ptoken
      AND membership.logins.provider=prov into return_id;
    end if;

    if not return_id is NULL then

        select can_login from membership.status
        inner join membership.members on membership.status.id = membership.members.membership_status_id
        where membership.members.id = return_id into member_can_login;

        if member_can_login then
            --yay!
            select true into success;

            select * from membership.members where membership.members.id=return_id into found_user;
            select 'Successfully authenticated' into message;
            select found_user.id into return_id;

            --a nice return name
            if found_user.first is null then
                select found_user.email into return_name;
            else
                select(found_user.first || ' ' || found_user.last) into return_name;
            end if;

            -- update user stats
            update membership.members set
            signin_count = signin_count + 1
            where id = return_id;

            -- deal with old sessions
            if exists(select id from membership.sessions where membership.sessions.member_id=return_id and expires_at >= now() ) then
                update membership.sessions set expires_at = now() where membership.sessions.member_id=return_id and expires_at >= now();
            end if;

            -- since this is a new login, create a new session - this will invalidate
            -- any shared login sessions where 2 people use the same account
            select session_length_weeks into session_length from membership.settings limit 1;

            --create a session
            insert into membership.sessions(member_id, created_at, expires_at, ip)
            values (return_id, now(), now() + interval '1 week' * session_length, ip) returning id into new_session_id;

            -- add a log entry
            insert into  membership.logs(subject, entry, member_id, created_at)
            values('authentication', 'Successfully logged in', return_id, now());

        else
            --TODO: Use a friendly message here from the DB
            select 'Currently unable to login' into message;
        end if;

    end if;

    return query
    --the command result has success, message, and a JSON package
    --select success, message, data_result;
    select return_id, new_session_id, message, pkey, success, return_name;

END;
$$ LANGUAGE PLPGSQL;

create or replace function change_password(
  member_email varchar(255),
  old_password varchar(255),
  new_password varchar(255)
)
returns TABLE(
  message varchar(255),
  succeeded bool
)
as $$
DECLARE
found_id bigint;
return_message varchar(255);
password_changed bool;
BEGIN
  --initial result
  select false into password_changed;

  --first, verify that the old password is correct and also find the user
  select membership.logins.member_id from membership.logins
  where membership.logins.provider_key=member_email
  AND membership.logins.provider_token = crypt(old_password,provider_token)
  AND membership.logins.provider='local' into found_id;


  if found_id IS NOT NULL THEN
    -- crypt the new one and save it
    update membership.logins set provider_token = crypt(new_password, gen_salt('bf', 10))
    where member_id = found_id AND provider='local';

    -- log the change
    insert into membership.logs(subject,entry,member_id, created_at)
    values('authentication','Password changed', found_id,now());

    select true into password_changed;
    select 'Password changed successfully' into return_message;
  else
    select 'User not found or password incorrect' into return_message;
    end if;

  return query
  select return_message,password_changed;
END;
$$ LANGUAGE PLPGSQL;

create or replace function get_current_user(session_id bigint)
returns TABLE(
    member_id bigint,
    email varchar(255),
    first varchar(50),
    last varchar(50),
    last_signin_at timestamptz,
    profile json,
    status varchar(20))
as
$$
DECLARE
found_id bigint;
found_user membership.members;
begin

    --session exist?
    if exists(select id from membership.sessions where id=session_id AND expires_at >= now()) then
        --get the user record
        select membership.sessions.member_id into found_id from membership.sessions where id=session_id;
        select * from membership.members where id=found_id into found_user;

        --reset the expiration on the session
        update membership.sessions set expires_at = now() + interval '2 weeks' where membership.sessions.id = session_id;

    end if;

    return query
    select found_user.id,
    found_user.email,
    found_user.first,
    found_user.last,
    found_user.last_signin_at,
    found_user.profile,
    found_user.status;

end;
$$ language plpgsql;

create or replace function get_member(member_id bigint)
returns setof member_summary
as $$
DECLARE
  found_user membership.members;
  parsed_logs json;
  parsed_notes json;
  parsed_roles json;
  member_status varchar(50);
  member_can_login bool;
  member_is_admin bool;
BEGIN

  if exists(select members.id from membership.members where members.id=member_id) then
    select * into found_user from membership.members where members.id=member_id;

    select name into member_status
    from membership.status
    where membership.status.id = found_user.membership_status_id;

    select membership.status.can_login into member_can_login
    from membership.status
    where membership.status.id = found_user.membership_status_id;

    select exists (select membership.members_roles.member_id
                  from membership.members_roles
                  where membership.members_roles.member_id = found_user.id AND role_id = 10) into member_is_admin;

    select json_agg(x) into parsed_logs from
    (select * from membership.logs where membership.logs.member_id=found_user.id) x;

    select json_agg(y) into parsed_notes from
    (select * from membership.notes where membership.notes.member_id=found_user.id) y;

    select json_agg(z) into parsed_roles from
    (select * from membership.roles
    inner join membership.members_roles on membership.roles.id = membership.members_roles.role_id
    where membership.members_roles.member_id=found_user.id) z;



  end if;

  return query
  select found_user.id,
  found_user.email,
  member_status,
  member_can_login,
  member_is_admin,
  found_user.first,
  found_user.last,
  found_user.member_key,
  found_user.email_validation_token,
  found_user.created_at,
  found_user.signin_count,
  found_user.social,
  found_user.location,
  parsed_logs,
  parsed_notes,
  parsed_roles;
end;
$$ LANGUAGE PLPGSQL;

create or replace function get_member_by_email(member_email varchar(255))
returns setof member_summary
as $$
DECLARE found_id bigint;
BEGIN
  select id
  from membership.members
  into found_id
  where email = member_email;

  return query
  select * from membership.get_member(found_id);
END;
$$ LANGUAGE PLPGSQL;


create or replace function register(
    new_email varchar(255),
    pass varchar(255),
    confirm varchar(255)
)

returns TABLE (
    new_id bigint,
    message varchar(255),
    email varchar(255),
    success BOOLEAN,
    status int,
    email_validation_token varchar(36))  
as
$$
DECLARE
    new_id bigint;
    message varchar(255);
    hashedpw varchar(255);
    success BOOLEAN;
    return_email varchar(255);
    return_status int;
    validation_token varchar(36);
    verify_email boolean;

BEGIN
    --default this to 'Not Approved'
    select 30 into return_status;
    select false into success;

    select new_email into return_email;

    if(pass <> confirm) THEN
        select 'Password and confirm do not match' into message;

    elseif exists(select membership.members.email from membership.members where membership.members.email=return_email)  then
        select 0 into new_id;
        select 'Email exists' into message;
    ELSE
        select true into success;
        --encrypt password
        SELECT membership.crypt(pass, membership.gen_salt('bf', 10)) into hashedpw;
        select membership.random_value(36) into validation_token;

        insert into membership.members(email, created_at, membership_status_id,email_validation_token)
        VALUES(new_email, now(), return_status, validation_token) returning id into new_id;

        select 'Successfully registered' into message;

        --add login bits to member_logins
        insert into membership.logins(member_id, provider, provider_key, provider_token)
        values(new_id, 'local',return_email,hashedpw);

        --add auth token
        insert into membership.logins(member_id, provider, provider_key, provider_token)
        values(new_id, 'token',null,validation_token);

        -- add them to the members role
        insert into membership.members_roles(member_id, role_id)
        VALUES(new_id, 99);

        --add log entry
        insert into membership.logs(subject,entry,member_id, created_at)
        values('registration','Added to system, set role to User',new_id,now());

        --if the settings say we don't need to verify them, then activate now
        select email_validation_required into verify_email from membership.settings limit 1;

        if verify_email = false then
          perform membership.change_status(return_email,10,'Activated member during registration');
        end if;

        --TODO: Mailer
    end if;

    return query
    select new_id, message, new_email, success, return_status, validation_token;
END;
$$ LANGUAGE PLPGSQL;

create or replace function remove_member_from_role(
  member_email varchar(255),
  remove_role_id int, out succeeded bool
)
as $$
DECLARE
  found_member_id bigint;
  selected_role varchar(50);
BEGIN
  select false into succeeded;
  if exists(select id from membership.members where email=member_email) then
    select id into found_member_id from membership.members where email=member_email;
    delete from membership.members_roles where member_id=found_member_id AND role_id=remove_role_id;
    --add a log entry
    select description into selected_role from membership.roles where id=remove_role_id;
    insert into logs(subject,entry,member_id, created_at)
    values('registration','Member removed from role ' || selected_role,found_member_id,now());
    select true into succeeded;
  end if;
END;
$$ LANGUAGE PLPGSQL;

create or replace function change_status(member_email varchar(255), new_status_id int, message varchar(255),out succeeded bool)
as $$
DECLARE
found_id bigint;
BEGIN
  select false into succeeded;
  select id into found_id from membership.members where email=member_email;
  if found_id IS NOT NULL THEN
    update membership.members set membership_status_id=new_status_id where email=member_email;
    --add a log entry
    insert into membership.logs(subject,entry,member_id, created_at)
    values('authentication',message,found_id,now());
    select true into succeeded;
  end if;
END;
$$ LANGUAGE PLPGSQL;


create or replace function lock_member(member_email varchar(255),out succeeded bool)
as $$
DECLARE
found_id bigint;
BEGIN
  select membership.change_status(member_email,88,'Member locked out') into succeeded;
END;

$$ LANGUAGE PLPGSQL;

create or replace function suspend_member(member_email varchar(255), reason varchar(512),out succeeded bool)
as $$
DECLARE
found_id bigint;
BEGIN
  select membership.change_status(member_email,20,'Member suspended: ' || reason) into succeeded;
END;
$$ LANGUAGE PLPGSQL;

create or replace function ban_member(member_email varchar(255), reason varchar(512),out succeeded bool)
as $$
BEGIN
  select membership.change_status(member_email,99,'Member banned: ' || reason) into succeeded;
END;

$$ LANGUAGE PLPGSQL;

create or replace function activate_member(member_email varchar(255),out succeeded bool)
as $$
DECLARE
BEGIN
  select membership.change_status(member_email,10,'Activated member') into succeeded;
END;
$$ LANGUAGE PLPGSQL;


select 'functions installed' as result;

COMMIT;