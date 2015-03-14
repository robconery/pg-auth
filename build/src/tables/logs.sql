create table logs(
    id serial primary key not null,
    subject log_type,
    member_id bigint not null,
    entry text not null,
    data json,
    created_at timestamptz default current_timestamp
);