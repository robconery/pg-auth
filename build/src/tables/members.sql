create table members(
    id bigint primary key not null unique DEFAULT id_generator(),
    first varchar(25),
    last varchar(25),
    member_key varchar(12) not null unique default random_value(12),
    email_validation_token varchar(36) default random_value(36),
    reset_password_token varchar(36),
    reset_password_token_set_at timestamptz,
    email varchar(255) unique not null,
    search tsvector,
    created_at timestamptz DEFAULT current_timestamp,
    signin_count int,
    membership_status_id int not null,
    social json,
    location json
);

CREATE TRIGGER members_search_vector_refresh
BEFORE INSERT OR UPDATE ON members
FOR EACH ROW EXECUTE PROCEDURE
tsvector_update_trigger(search, 'pg_catalog.english',  email, first, last);

