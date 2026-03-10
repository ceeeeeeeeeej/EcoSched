-- 1. Create a function to handle new special collection requests
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
    resident_name TEXT;
BEGIN
    -- Try to get resident name from metadata if available, else use a fallback
    resident_name := COALESCE(NEW.metadata->>'resident_name', 'A resident');

    -- Loop through all admins and superadmins
    FOR admin_user IN 
        SELECT id FROM "public"."users" 
        WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO "public"."notifications" (
            "user_id",
            "title",
            "message",
            "type",
            "priority",
            "is_read",
            "created_at"
        ) VALUES (
            admin_user.id,
            'New Pickup Request',
            resident_name || ' has requested a special collection.',
            'special_collection',
            'medium',
            false,
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the trigger
DROP TRIGGER IF EXISTS on_special_collection_created ON "public"."special_collections";

CREATE TRIGGER on_special_collection_created
AFTER INSERT ON "public"."special_collections"
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_special_collection();

-- 3. Ensure Notifications RLS allows reading
-- (Admins need to see their own notifications)
ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON "public"."notifications";
CREATE POLICY "Users can view own notifications" 
ON "public"."notifications" 
FOR SELECT 
USING (auth.uid() = user_id);

-- 4. Grant permissions just in case
GRANT SELECT, INSERT, UPDATE, DELETE ON "public"."notifications" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON "public"."notifications" TO service_role;
