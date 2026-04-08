DO $$
DECLARE
    cristine_uuid UUID;
    admin_user RECORD;
    sc_record RECORD;
    resident_name TEXT;
BEGIN
    -- 1. Get cristine@gmail.com's UUID from the secure auth table
    SELECT id INTO cristine_uuid FROM auth.users WHERE email = 'cristine@gmail.com' LIMIT 1;
    
    -- 2. Ensure cristine is registered as an admin in the public users table so she gets alerts!
    IF cristine_uuid IS NOT NULL THEN
        INSERT INTO "public"."users" (id, email, first_name, role, status)
        VALUES (cristine_uuid, 'cristine@gmail.com', 'Cristine', 'admin', 'active')
        ON CONFLICT (id) DO UPDATE SET role = 'admin';
    END IF;

    -- 3. Clear existing special collection notifications to avoid duplicates
    DELETE FROM "public"."user_notifications" WHERE type = 'special_collection';

    -- 4. Backfill notifications for all existing special collections
    FOR sc_record IN 
        SELECT sc.created_at, sc.metadata, u.first_name, u.last_name
        FROM "public"."special_collections" sc
        LEFT JOIN "public"."users" u ON sc.resident_id::text = u.id::text
    LOOP
        -- Determine the resident's name
        IF sc_record.first_name IS NOT NULL THEN
            resident_name := sc_record.first_name || ' ' || COALESCE(sc_record.last_name, '');
        ELSE
            -- Fall back to metadata or "A resident"
            resident_name := COALESCE(sc_record.metadata->>'resident_name', 'A resident');
        END IF;

        -- Create a notification for EVERY admin in the system
        FOR admin_user IN 
            SELECT id FROM "public"."users" WHERE role IN ('admin', 'superadmin')
        LOOP
            INSERT INTO "public"."user_notifications" (
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
                resident_name || ' has requested a special collection for General Waste.',
                'special_collection',
                'medium',
                false,
                sc_record.created_at
            );
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
