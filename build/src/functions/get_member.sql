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