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