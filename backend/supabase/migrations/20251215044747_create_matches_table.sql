create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user1_id uuid not null references public.users(id) on delete cascade,
  user2_id uuid not null references public.users(id) on delete cascade,
  work1_id uuid not null references public.works(id) on delete cascade,
  work2_id uuid not null references public.works(id) on delete cascade,
  created_at timestamp with time zone default now(),
  unique (user1_id, user2_id)
);