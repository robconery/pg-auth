set search_path = membership;

ALTER TABLE logins 
ADD CONSTRAINT logins_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE logs 
ADD CONSTRAINT logs_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE notes 
ADD CONSTRAINT notes_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE members_roles 
ADD CONSTRAINT member_roles_members 
FOREIGN KEY (member_id) REFERENCES members (id) on delete cascade;

ALTER TABLE members_roles 
ADD CONSTRAINT member_roles_roles
FOREIGN KEY (role_id) REFERENCES roles (id) on delete cascade;

ALTER TABLE sessions 
ADD CONSTRAINT sessions_members
FOREIGN KEY (member_id) REFERENCES members(id) on delete cascade;