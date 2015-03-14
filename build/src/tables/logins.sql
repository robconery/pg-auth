create table logins (
    id bigint primary key not null unique DEFAULT id_generator(),
    member_id bigint not null,
    provider varchar(50) not null default 'local',
    provider_key varchar(255),
    provider_token varchar(255) not null
);