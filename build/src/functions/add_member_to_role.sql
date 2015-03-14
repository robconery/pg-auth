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