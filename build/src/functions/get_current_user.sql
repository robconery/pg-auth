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