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