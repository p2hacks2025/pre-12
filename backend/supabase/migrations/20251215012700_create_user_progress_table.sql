CREATE TABLE public.user_progress (
  user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  last_viewed timestamp with time zone
);
