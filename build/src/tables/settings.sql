create table settings(
    id serial primary key not null,
    allow_token_login boolean not null default true,
    lock_trigger int not null default 0,
    reset_password_within_hours int not null default 6,
    session_length_weeks int not null default 2,
    email_validation_required boolean not null default false,
    email_from_name varchar(50) not null,
    email_from_address varchar(125) not null
);

insert into membership.settings(email_from_name, email_from_address)
values ('Admin', 'admin@example.com');