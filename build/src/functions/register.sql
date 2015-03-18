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
    select 30, false, new_email into return_status, success, return_email;

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