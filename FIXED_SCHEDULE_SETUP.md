# Fixed Schedule Setup for Supabase

This guide explains how to set up and manage fixed collection schedules (e.g., Victoria and Dayo-an) using the Supabase database.

## 1. Database Schema
The and `area_schedules` table stores the configuration for fixed recurring schedules.

```sql
CREATE TABLE IF NOT EXISTS area_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    area VARCHAR(50) UNIQUE NOT NULL,
    schedule_name VARCHAR(100) NOT NULL,
    days TEXT[] NOT NULL,
    time TIME NOT NULL DEFAULT '08:00:00',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 2. Initializing Areas
Run the following SQL to set up the default areas:

```sql
INSERT INTO area_schedules (area, schedule_name, days, time) VALUES
('victoria', 'Victoria Waste Collection', ARRAY['monday', 'tuesday'], '08:00:00'),
('dayo-an', 'Dayo-an Waste Collection', ARRAY['saturday'], '08:00:00')
ON CONFLICT (area) DO NOTHING;
```

## 3. How it Works
1. **Flutter App**: The `PickupService` loads data from `area_schedules` to calculate upcoming collection dates.
2. **Admin Dashboard**: Use the `Schedules` page to view and manage these areas. Fixed schedules are marked with a "FIXED" label.
3. **Rescheduling**: To override a fixed schedule for a specific date (e.g., due to a holiday), use the "Emergency Rescheduled" button in the Admin Dashboard. This creates a record in `collection_schedules` with `is_rescheduled = true`, which the services prioritizes over the fixed rule.

## 4. Maintenance
To add a new area with a fixed schedule, simply insert a new row into the `area_schedules` table. No code changes are required in the Flutter app or Dashboard to support new areas.
