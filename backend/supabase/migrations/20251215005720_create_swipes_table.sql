CREATE TABLE public.swipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  to_work_id uuid NOT NULL REFERENCES public.works(id) ON DELETE CASCADE,
  to_work_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_like boolean NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  UNIQUE (from_user_id, to_work_id)
);
