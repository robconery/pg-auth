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