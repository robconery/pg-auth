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