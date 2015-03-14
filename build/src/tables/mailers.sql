create table mailers(
    id serial primary key not null,
    name varchar(255) not null,
    from_address varchar(255),
    from_name varchar(255),
    subject varchar(255),
    template_markdown text
);

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('Welcome','noreply@site.com','Admin','Welcome to Our Site','Welcome to our site!');

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('password-reset','noreply@site.com','Admin','Password Reset Instructions','Welcome to our site!');

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('validation','noreply@site.com','Admin','Email Validation Request','Welcome to our site!');

insert into membership.mailers(name,from_address,from_name, subject, template_markdown)
values('general','noreply@site.com','Admin','Welcome to Our Site','Welcome to our site!');