-- ECOSCHED FULL DATABASE RECOVERY SCRIPT
-- RUN THIS IN SUPABASE SQL EDITOR

-- 0. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Area Schedules
CREATE TABLE IF NOT EXISTS public.area_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    area VARCHAR(50) UNIQUE NOT NULL,
    schedule_name VARCHAR(100) NOT NULL,
    days TEXT[] NOT NULL,
    time TIME NOT NULL DEFAULT '08:00:00',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Users (Core Profile)
CREATE TABLE IF NOT EXISTS public.users (
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

-- 3. Registered Collectors
CREATE TABLE IF NOT EXISTS public.registered_collectors (
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

-- 4. Collection Schedules
CREATE TABLE IF NOT EXISTS public.collection_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    zone VARCHAR(50) NOT NULL,
    collection_time TIMESTAMP WITH TIME ZONE NOT NULL,
    collector_id UUID REFERENCES public.registered_collectors(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'scheduled',
    description TEXT,
    is_rescheduled BOOLEAN DEFAULT FALSE,
    original_date TIMESTAMP WITH TIME ZONE,
    rescheduled_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    name VARCHAR(255),
    scheduled_date TIMESTAMP WITH TIME ZONE
);

-- 5. Special Collections
CREATE TABLE IF NOT EXISTS public.special_collections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    resident_id TEXT, -- Support both Auth UUID and Device ID
    resident_name TEXT,
    resident_barangay TEXT,
    resident_purok TEXT,
    waste_type TEXT NOT NULL,
    estimated_quantity TEXT,
    preferred_date DATE,
    preferred_time VARCHAR(50),
    pickup_location TEXT NOT NULL,
    message TEXT,
    status TEXT DEFAULT 'pending',
    payment_reference VARCHAR(100),
    payment_amount DECIMAL(10, 2),
    scheduled_date TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Bins
CREATE TABLE IF NOT EXISTS public.bins (
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

-- 7. Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Resident Feedback
CREATE TABLE IF NOT EXISTS public.resident_feedback (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    feedback_text TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure all enhanced columns exist (Check each individually)
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='resident_id') THEN ALTER TABLE public.resident_feedback ADD COLUMN resident_id TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='resident_name') THEN ALTER TABLE public.resident_feedback ADD COLUMN resident_name TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='resident_email') THEN ALTER TABLE public.resident_feedback ADD COLUMN resident_email TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='category') THEN ALTER TABLE public.resident_feedback ADD COLUMN category TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='subject') THEN ALTER TABLE public.resident_feedback ADD COLUMN subject TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='priority') THEN ALTER TABLE public.resident_feedback ADD COLUMN priority TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='service_area') THEN ALTER TABLE public.resident_feedback ADD COLUMN service_area TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='barangay') THEN ALTER TABLE public.resident_feedback ADD COLUMN barangay TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='purok') THEN ALTER TABLE public.resident_feedback ADD COLUMN purok TEXT; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='resident_feedback' AND column_name='status') THEN ALTER TABLE public.resident_feedback ADD COLUMN status VARCHAR(20) DEFAULT 'new'; END IF; END $$;

-- 9. Announcements
CREATE TABLE IF NOT EXISTS public.announcements (
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

-- 10. System Settings, Reminders, Routes (Minimal creation to ensure integrity)
CREATE TABLE IF NOT EXISTS public.system_settings (id UUID DEFAULT uuid_generate_v4() PRIMARY KEY, key VARCHAR(100) UNIQUE NOT NULL, value TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW());
CREATE TABLE IF NOT EXISTS public.reminders (id UUID DEFAULT uuid_generate_v4() PRIMARY KEY, user_id UUID REFERENCES users(id) ON DELETE CASCADE, title VARCHAR(255) NOT NULL, reminder_time TIMESTAMP WITH TIME ZONE NOT NULL, is_sent BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW());
CREATE TABLE IF NOT EXISTS public.routes (id UUID DEFAULT uuid_generate_v4() PRIMARY KEY, name VARCHAR(100) NOT NULL, zone VARCHAR(50), waypoints JSONB, collector_id UUID REFERENCES registered_collectors(id) ON DELETE SET NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW());

-- 11. Triggers & Functions
CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ language 'plpgsql';

DO $$ 
DECLARE t text;
BEGIN
    FOR t IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('area_schedules', 'users', 'registered_collectors', 'collection_schedules', 'special_collections', 'bins', 'resident_feedback', 'announcements', 'reminders', 'routes', 'system_settings')
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS update_%I_updated_at ON %I', t, t);
        EXECUTE format('CREATE TRIGGER update_%I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
    END LOOP;
END $$;

-- 12. RLS & Policies
ALTER TABLE public.special_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resident_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- SPECIAL COLLECTIONS POLICIES
DROP POLICY IF EXISTS "Anyone can insert special_collections" ON public.special_collections;
CREATE POLICY "Anyone can insert special_collections" ON public.special_collections FOR INSERT TO public WITH CHECK (true);
DROP POLICY IF EXISTS "Users view own special_collections" ON public.special_collections;
CREATE POLICY "Users view own special_collections" ON public.special_collections FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Users update own special_collections" ON public.special_collections;
CREATE POLICY "Users update own special_collections" ON public.special_collections FOR UPDATE TO public USING (true);

-- COLLECTION SCHEDULES POLICIES
DROP POLICY IF EXISTS "Everyone read collection_schedules" ON public.collection_schedules;
CREATE POLICY "Everyone read collection_schedules" ON public.collection_schedules FOR SELECT USING (true);

-- RESIDENT FEEDBACK POLICIES
DROP POLICY IF EXISTS "Anyone can insert resident_feedback" ON public.resident_feedback;
CREATE POLICY "Anyone can insert resident_feedback" ON public.resident_feedback FOR INSERT TO public WITH CHECK (true);
DROP POLICY IF EXISTS "Users view own feedback" ON public.resident_feedback;
CREATE POLICY "Users view own feedback" ON public.resident_feedback FOR SELECT TO public USING (true);

-- 13. Permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT, INSERT ON public.special_collections, public.resident_feedback TO anon;
GRANT SELECT ON public.collection_schedules TO anon;

-- 14. Force Schema Refresh
NOTIFY pgrst, 'reload schema';
