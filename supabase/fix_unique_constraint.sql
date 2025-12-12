-- Add unique constraint to avoid 42P10 error on UPSERT
ALTER TABLE public.user_devices
ADD CONSTRAINT user_devices_fcm_token_key UNIQUE (fcm_token);
