create table public.users (
  id uuid primary key default gen_random_uuid(),
  username text not null,
  icon_url text
);
