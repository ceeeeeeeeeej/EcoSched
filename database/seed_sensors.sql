-- SQL Migration: Create bins table and seed dummy sensors
-- Run this in your Supabase SQL Editor

-- 1. Create bins table if it doesn't exist
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

-- 2. (Optional) Manual Seed Data
-- The sensor (BIN-1189) will now auto-register itself when it connects.
-- You can add other manual entries here if needed.

-- 4. Verify the insertions
SELECT bin_id, address, zone, fill_level, status, last_emptied
FROM bins
WHERE bin_id IN ('BIN-1189')
ORDER BY bin_id;
