CREATE TABLE public.works (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  title text NOT NULL,
  description text,
  created_at timestamp with time zone DEFAULT now()
);
