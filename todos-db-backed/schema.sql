create table lists (
  id serial primary key,
  name text unique not null
);

create table todos (
  id serial primary key,
  name text not null,
  completed boolean default false,
  list_id integer not null references list(id) on delete cascade
);