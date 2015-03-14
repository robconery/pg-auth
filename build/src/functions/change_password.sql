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