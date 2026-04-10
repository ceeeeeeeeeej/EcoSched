-- ============================================================
-- Ten Year Solid Waste Management Plan — Supabase Table
-- Run this in the Supabase SQL Editor (or via migration tool)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.waste_management_plans (
    id              BIGSERIAL PRIMARY KEY,
    plan_name       TEXT NOT NULL DEFAULT 'Ten Year Solid Waste Management Plan',
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Full sector × waste-type matrix (JSON object)
    -- e.g. { "residential": { "biodegradable": 2808.13, "recyclable": 2106.10, ... }, ... }
    waste_data      JSONB NOT NULL DEFAULT '{}',

    -- Pre-computed sector row totals
    -- e.g. { "residential": 5850.23, "commercial": 4390.83, ... }
    sector_totals   JSONB NOT NULL DEFAULT '{}',

    -- Pre-computed waste-type column totals
    -- e.g. { "biodegradable": 5850.28, "recyclable": 4387.24, ... }
    type_totals     JSONB NOT NULL DEFAULT '{}',

    -- Grand total across all sectors and waste types (kg)
    grand_total_kg  NUMERIC(12, 2) NOT NULL DEFAULT 0,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.waste_management_plans ENABLE ROW LEVEL SECURITY;

-- Policy: allow authenticated (admin) users full access
CREATE POLICY "admin_full_access" ON public.waste_management_plans
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Allow anonymous reads (for viewing generated reports without login if desired)
-- Comment out or drop this policy if you want it strictly admin-only:
-- CREATE POLICY "anon_read" ON public.waste_management_plans
--     FOR SELECT USING (true);

-- Index for fast queries by plan name and date
CREATE INDEX IF NOT EXISTS idx_wmp_plan_name      ON public.waste_management_plans (plan_name);
CREATE INDEX IF NOT EXISTS idx_wmp_generated_at   ON public.waste_management_plans (generated_at DESC);

COMMENT ON TABLE public.waste_management_plans IS
    'Stores each generated Ten Year Solid Waste Management Plan dataset, including per-sector and per-waste-type totals.';
