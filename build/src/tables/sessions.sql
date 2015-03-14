create table sessions(
    id bigint primary key not null unique DEFAULT id_generator(),
    token varchar(24) not null unique default random_value(24),
    ip inet,
    member_id bigint not null,
    created_at timestamptz not null DEFAULT current_timestamp,
    expires_at timestamptz not null
);