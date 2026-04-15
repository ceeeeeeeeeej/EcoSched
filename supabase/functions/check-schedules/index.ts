import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const ManilaTime = {
    now: () => {
        const d = new Date();
        const utc = d.getTime() + (d.getTimezoneOffset() * 60000);
        return new Date(utc + (3600000 * 8));
    },
    toHHMM: (date: Date) => {
        const h = String(date.getHours()).padStart(2, "0");
        const m = String(date.getMinutes()).padStart(2, "0");
        return `${h}:${m}`;
    },
    toISODate: (date: Date) => {
        return date.toISOString().split("T")[0];
    },
    getDayName: (date: Date) => {
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        return days[date.getDay()];
    }
};

function isWithinWindow(targetTime: string, currentTime: string, windowMinutes: number = 10) {
    const [th, tm] = targetTime.split(":").map(Number);
    const [ch, cm] = currentTime.split(":").map(Number);
    const targetInMinutes = (th * 60) + tm;
    const currentInMinutes = (ch * 60) + cm;
    const diff = Math.abs(currentInMinutes - targetInMinutes);
    return diff <= windowMinutes;
}

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

    try {
        const url = new URL(req.url);
        const testBarangay = url.searchParams.get("test");
        const delaySeconds = parseInt(url.searchParams.get("delay") || "0");

        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseKey);

        const nowManila = ManilaTime.now();
        const timeStr = ManilaTime.toHHMM(nowManila);
        const todayStr = ManilaTime.toISODate(nowManila);
        const dayName = ManilaTime.getDayName(nowManila);

        // 🧪 TEST MODE
        if (testBarangay) {
            if (delaySeconds > 0) await new Promise(r => setTimeout(r, Math.min(delaySeconds, 50) * 1000));
            await processAlert(supabase, testBarangay, timeStr, todayStr, `test_${Date.now()}`, "🔔 BILINGUAL TEST | PASALIG NGA TEST", `Success! Bilingual notifications are live for ${testBarangay}. | Kalamposan! Ang bilingual nga pahibalo buhi na para sa ${testBarangay}.`);
            return new Response(JSON.stringify({ success: true, mode: "test" }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        // --- PHASE 1: 6:00 PM (TOMORROW REMINDER) ---
        if (isWithinWindow("18:00", timeStr)) {
            const tomorrow = new Date(nowManila.getTime() + (24 * 60 * 60 * 1000));
            const tomStr = ManilaTime.toISODate(tomorrow);
            const tomDay = ManilaTime.getDayName(tomorrow);

            const title = "🗓️ Collection Tomorrow | Koleksyon Ugma";
            const body = "Reminder: Waste collection in Victoria is scheduled for tomorrow. | Pahibalo: Adunay pagkolekta sa basura sa Victoria ugma sa buntag.";

            // Specific
            const { data: spec } = await supabase.from("collection_schedules").select("*").eq("status", "Scheduled").ilike("scheduled_date", `${tomStr}%`);
            if (spec) for (const s of spec) await processAlert(supabase, normalize(s.zone), "18:00", todayStr, `tom_${s.id}`, title, body);

            // Recurring
            const { data: rec } = await supabase.from("area_schedules").select("*").eq("is_active", true).contains("days", [tomDay]);
            if (rec) for (const r of rec) await processAlert(supabase, normalize(r.area), "18:00", todayStr, `tom_rec_${r.id}`, title, `Heads up! Your regular ${capitalize(tomDay)} collection is tomorrow. | Pahibalo! Ang imong regular nga koleksyon karong ${capitalize(tomDay)} kay ugma na.`);
        }

        // --- PHASE 2: 6:00 AM (PREPARATION) ---
        if (isWithinWindow("06:00", timeStr)) {
            const title = "🚛 Preparation Alert | Alerto sa Pagpangandam";
            const body = "Preparation time! Please move your garbage to the designated area. | Panahon na sa pagpangandam! Palihog ibutang ang inyong basura sa designated area.";

            // Specific
            const { data: spec } = await supabase.from("collection_schedules").select("*").eq("status", "Scheduled").ilike("scheduled_date", `${todayStr}%`);
            if (spec) for (const s of spec) await processAlert(supabase, normalize(s.zone), "06:00", todayStr, `prep_${s.id}`, title, body);

            // Recurring
            const { data: rec } = await supabase.from("area_schedules").select("*").eq("is_active", true).contains("days", [dayName]);
            if (rec) for (const r of rec) await processAlert(supabase, normalize(r.area), "06:00", todayStr, `prep_rec_${r.id}`, title, body);
        }

        // --- PHASE 3: 8:00 AM (COLLECTION STARTING) ---
        if (isWithinWindow("08:00", timeStr)) {
            const title = "🔔 Collection starting now! | Koleksyon magsugod na!";
            const body = "The truck is starting its rounds! Please ensure your garbage is ready. | Ang truck nagsugod na sa koleksyon! Palihog siguroha nga andam na ang inyong basura.";

            // Specific
            const { data: spec } = await supabase.from("collection_schedules").select("*").eq("status", "Scheduled").ilike("scheduled_date", `${todayStr}%`);
            if (spec) for (const s of spec) await processAlert(supabase, normalize(s.zone), "08:00", todayStr, `start_${s.id}`, title, body);

            // Recurring
            const { data: rec } = await supabase.from("area_schedules").select("*").eq("is_active", true).contains("days", [dayName]);
            if (rec) for (const r of rec) await processAlert(supabase, normalize(r.area), "08:00", todayStr, `start_rec_${r.id}`, title, body);
        }

        return new Response(JSON.stringify({ success: true, processed_at: timeStr }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }
});

function normalize(b: string) { return b.toLowerCase().includes('victoria') ? 'Victoria' : b; }
function capitalize(s: string) { return s.charAt(0).toUpperCase() + s.slice(1); }

async function processAlert(supabase: any, barangay: string, schedTime: string, dateStr: string, uniqueRef: string, title: string, body: string) {
    const dRef = `${uniqueRef}_${barangay}_${dateStr}_${schedTime}`;
    const { data: existing } = await supabase.from("user_notifications").select("id").eq("barangay", barangay).eq("metadata->>dedup_key", dRef).limit(1);
    if (existing && existing.length > 0 && !uniqueRef.startsWith("test")) return;
    await supabase.functions.invoke("send-push-v2", { body: { title, body, type: "alert", barangay, collapse_key: `schedule_${barangay}` } });
    await supabase.from("user_notifications").insert({ title, message: body, type: "alert", barangay, metadata: { dedup_key: dRef } });
}
