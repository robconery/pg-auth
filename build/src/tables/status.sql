create table status(
    id int  primary key not null,
    name varchar(50),
    description varchar(255),
    can_login boolean not null default true
);

-- default statuses
insert into membership.status(id, name, description) values(10, 'Active', 'User can login, etc');
insert into membership.status(id, name, description,can_login) values(20, 'Suspended','Cannot login for a given reason',false);
insert into membership.status(id, name, description,can_login) values(30, 'Not Approved','Member needs to be approved (email validation, etc)',false);
insert into membership.status(id, name, description,can_login) values(99, 'Banned','Member has been banned',false);
insert into membership.status(id, name, description,can_login) values(88, 'Locked', 'Member is locked out due to failed logins',false);