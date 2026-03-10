-- EcoSched Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Area Schedules Table (Fixed Weekly Schedules)
CREATE TABLE IF NOT EXISTS area_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    area VARCHAR(50) UNIQUE NOT NULL,
    schedule_name VARCHAR(100) NOT NULL,
    days TEXT[] NOT NULL, -- e.g. ['monday', 'tuesday']
    time TIME NOT NULL DEFAULT '08:00:00',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Users table (for authentication profiles)
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'resident',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Registered Collectors table
CREATE TABLE IF NOT EXISTS registered_collectors (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'collector',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Collection Schedules (Actual instances/overrides)
CREATE TABLE IF NOT EXISTS collection_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    zone VARCHAR(50) NOT NULL,
    collection_time TIMESTAMP WITH TIME ZONE NOT NULL,
    collector_id UUID REFERENCES registered_collectors(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, on_the_way, completed, cancelled
    description TEXT,
    is_rescheduled BOOLEAN DEFAULT FALSE,
    original_date TIMESTAMP WITH TIME ZONE,
    rescheduled_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Special Collections
CREATE TABLE IF NOT EXISTS special_collections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    resident_id UUID REFERENCES users(id) ON DELETE CASCADE, -- User requesting
    waste_type VARCHAR(100) NOT NULL,
    estimated_quantity TEXT,
    preferred_date DATE NOT NULL,
    preferred_time VARCHAR(50),
    pickup_location TEXT NOT NULL,
    special_instructions TEXT,
    payment_reference VARCHAR(100),
    payment_amount DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'pending_payment', -- pending_payment, payment_submitted, scheduled, completed, cancelled
    scheduled_date TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Bins table
CREATE TABLE IF NOT EXISTS bins (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    bin_id VARCHAR(50) UNIQUE NOT NULL,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    address TEXT,
    zone VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active',
    fill_level INTEGER DEFAULT 0 CHECK (fill_level >= 0 AND fill_level <= 100),
    last_emptied TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- info, warning, alert
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. User Activities table
CREATE TABLE IF NOT EXISTS user_activities (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. System Settings table
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Resident Feedback table
CREATE TABLE IF NOT EXISTS resident_feedback (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    feedback_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Announcements table
CREATE TABLE IF NOT EXISTS announcements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    target_audience VARCHAR(50) DEFAULT 'all',
    priority VARCHAR(20) DEFAULT 'normal',
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Reminders table
CREATE TABLE IF NOT EXISTS reminders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    reminder_time TIMESTAMP WITH TIME ZONE NOT NULL,
    type VARCHAR(50),
    is_sent BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Routes table
CREATE TABLE IF NOT EXISTS routes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    zone VARCHAR(50),
    waypoints JSONB,
    collector_id UUID REFERENCES registered_collectors(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_registered_collectors_email ON registered_collectors(email);
CREATE INDEX IF NOT EXISTS idx_collection_schedules_zone ON collection_schedules(zone);
CREATE INDEX IF NOT EXISTS idx_collection_schedules_time ON collection_schedules(collection_time);
CREATE INDEX IF NOT EXISTS idx_special_collections_resident ON special_collections(resident_id);
CREATE INDEX IF NOT EXISTS idx_bins_zone ON bins(zone);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active);

-- Update_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_area_schedules_updated_at BEFORE UPDATE ON area_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_registered_collectors_updated_at BEFORE UPDATE ON registered_collectors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_collection_schedules_updated_at BEFORE UPDATE ON collection_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_special_collections_updated_at BEFORE UPDATE ON special_collections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bins_updated_at BEFORE UPDATE ON bins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_resident_feedback_updated_at BEFORE UPDATE ON resident_feedback FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE area_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE registered_collectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE special_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE bins ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE resident_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- Basic Policies (Public read for critical tables, specific write for roles)

-- Area Schedules: Everyone can read, Admin can manage
CREATE POLICY "Public read area_schedules" ON area_schedules FOR SELECT USING (true);
CREATE POLICY "Admin manage area_schedules" ON area_schedules FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Users: Users view/update own, Admin view all
CREATE POLICY "Users view own profile" ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users update own profile" ON users FOR UPDATE USING (id = auth.uid());
CREATE POLICY "Admin view all users" ON users FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Collection Schedules: Everyone read, Admin/Collector update
CREATE POLICY "Everyone read collection_schedules" ON collection_schedules FOR SELECT USING (true);
CREATE POLICY "Admin/Collector manage collection_schedules" ON collection_schedules FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'collector'))
);

-- Special Collections: User view/update own, Admin manage all
CREATE POLICY "Users view/cancel own special_collections" ON special_collections FOR SELECT USING (resident_id = auth.uid());
CREATE POLICY "Users insert special_collections" ON special_collections FOR INSERT WITH CHECK (resident_id = auth.uid());
CREATE POLICY "Admin manage special_collections" ON special_collections FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Notifications: Users view own
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());

-- Insert default area schedules (matching FIXED_SCHEDULE_SETUP.md logic)
INSERT INTO area_schedules (area, schedule_name, days, time) VALUES
('victoria', 'Victoria Waste Collection', ARRAY['monday', 'tuesday'], '08:00:00'),
('dayo-an', 'Dayo-an Waste Collection', ARRAY['saturday'], '08:00:00')
ON CONFLICT (area) DO NOTHING;

-- 14. Full Bin Notification Trigger
-- Automatically notifies admins when a bin level >= 90%
CREATE OR REPLACE FUNCTION notify_full_bin()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    IF (NEW.fill_level >= 90 AND (OLD.fill_level < 90 OR OLD.fill_level IS NULL)) THEN
        FOR admin_user IN SELECT id FROM users WHERE role IN ('admin', 'superadmin') LOOP
            INSERT INTO notifications (user_id, title, message, type, metadata)
            VALUES (
                admin_user.id,
                'Bin Full Alert',
                'Bin ' || NEW.bin_id || ' at ' || COALESCE(NEW.address, NEW.zone) || ' is ' || NEW.fill_level || '% full.',
                'alert',
                jsonb_build_object('bin_id', NEW.bin_id, 'fill_level', NEW.fill_level)
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER bin_full_notification_trigger
AFTER UPDATE ON bins
FOR EACH ROW
EXECUTE FUNCTION notify_full_bin();
