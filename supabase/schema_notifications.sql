-- Create table for storing FCM tokens
CREATE TABLE IF NOT EXISTS public.user_devices (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT, -- 'android', 'ios', 'web'
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, fcm_token)
);

-- Enable RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- 1. Users can insert their own devices
CREATE POLICY "Users can insert their own devices" 
ON public.user_devices 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 2. Users can view their own devices
CREATE POLICY "Users can view their own devices" 
ON public.user_devices 
FOR SELECT 
USING (auth.uid() = user_id);

-- 3. Users can update their own devices
CREATE POLICY "Users can update their own devices" 
ON public.user_devices 
FOR UPDATE 
USING (auth.uid() = user_id);

-- 4. Users can delete their own devices
CREATE POLICY "Users can delete their own devices" 
ON public.user_devices 
FOR DELETE 
USING (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token ON public.user_devices(fcm_token);

-- NOTE: For the 'order delivered' trigger, you should use Supabase Dashboard > Database > Webhooks.
-- Create a webhook "order_delivered" on table "orders" for "UPDATE" events where "status" = 'DELIVERED'.
-- URL: https://<project-ref>.supabase.co/functions/v1/send_push_notification
-- Header: Authorization: Bearer <service_role_key> (or use anon key if function handles auth, but service role is better for background triggers)
