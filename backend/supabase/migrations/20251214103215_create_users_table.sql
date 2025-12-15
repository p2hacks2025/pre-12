create table public.users (
  id uuid primary key default gen_random_uuid(),
  username text not null,
  email text not null unique,
  password text not null,
  icon_url text
);
