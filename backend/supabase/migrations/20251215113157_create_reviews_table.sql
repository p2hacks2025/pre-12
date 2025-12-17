create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  from_user_id uuid not null references public.users(id) on delete cascade,
  to_user_id uuid not null references public.users(id) on delete cascade,
  work_id uuid not null references public.works(id) on delete cascade,
  comment text not null,
  created_at timestamp with time zone default now(),
  unique (match_id, from_user_id)
);