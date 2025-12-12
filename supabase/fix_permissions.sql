-- 1. Ensure Unique Constraint exists (safe to run even if exists)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_devices_fcm_token_key') THEN 
        ALTER TABLE public.user_devices ADD CONSTRAINT user_devices_fcm_token_key UNIQUE (fcm_token); 
    END IF; 
END $$;

-- 2. Disable RLS (Row Level Security) to match other tables
ALTER TABLE public.user_devices DISABLE ROW LEVEL SECURITY;

-- 3. Grant full access to authenticated users (just in case)
GRANT ALL ON public.user_devices TO postgres, anon, authenticated, service_role;
