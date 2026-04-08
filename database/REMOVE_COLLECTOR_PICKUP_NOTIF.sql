-- Update NEW PICKUP REQUEST notification to only target admins
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify Admins ONLY
    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id, 'New Pickup Request', 'A resident has requested a special collection for ' || NEW.waste_type || '.', 'info', 'medium', false, NOW()
    FROM public.users
    WHERE role = 'admin';

    -- NO COLLECTOR NOTIFICATION HERE (User wants to remove it)
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
