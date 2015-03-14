create table notes(
    id serial primary key not null,
    member_id bigint not null,
    note text not null,
    created_at timestamptz default current_timestamp
);