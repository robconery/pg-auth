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
