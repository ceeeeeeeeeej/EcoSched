-- Add metadata column to special_collections if it's missing
ALTER TABLE "public"."special_collections" 
ADD COLUMN IF NOT EXISTS "metadata" JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS "cancelled_at" TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS "cancellation_reason" TEXT;

-- Refresh the schema cache (Supabase specific, usually happens automatically but good to trigger a change)
NOTIFY pgrst, 'reload config';
