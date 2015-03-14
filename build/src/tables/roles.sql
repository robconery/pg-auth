create table roles(
    id integer primary key not null,
    description varchar(24) not null
);

create table members_roles(
    member_id bigint not null,
    role_id int not null,
    primary key (member_id, role_id)
);

-- default roles
insert into membership.roles (id, description) values(10, 'Administrator');
insert into membership.roles (id, description) values(99, 'User');
