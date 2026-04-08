import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ManilaTime = {
  getCurrent: () => {
    const now = new Date();
    // Offset for Manila (UTC+8)
    return new Date(now.getTime() + (8 * 60 * 60 * 1000));
  },
  toISODate: (date: Date) => date.toISOString().split('T')[0],
  toHHMM: (date: Date) => {
    const h = date.getUTCHours().toString().padStart(2, '0');
    const m = date.getUTCMinutes().toString().padStart(2, '0');
    return `${h}:${m}`;
  }
};

/**
 * Checks if a scheduled time (HH:mm) is within a 10-minute window (+/- 5 mins) of current time.
 */
function isWithinWindow(schedTime: string, currentTime: string): boolean {
  try {
    const [sH, sM] = schedTime.split(':').map(Number);
    const [cH, cM] = currentTime.split(':').map(Number);
    
    const schedTotalMinutes = sH * 60 + sM;
    const currentTotalMinutes = cH * 60 + cM;
    
    const diff = Math.abs(currentTotalMinutes - schedTotalMinutes);
    // 5 minute window before/after (total 10-11 mins)
    return diff <= 5;
  } catch (e) {
    return false;
  }
}

serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    const nowManila = ManilaTime.getCurrent();
    const todayStr = ManilaTime.toISODate(nowManila);
    const timeStr = ManilaTime.toHHMM(nowManila);
    
    console.log(`⏰ Cron check started at ${timeStr} (Manila Time: ${nowManila.toISOString()})`);

    // --- 1. DAILY REMINDERS AT 18:00 (6:00 PM) ---
    if (timeStr === "18:00") {
      const tomorrow = new Date(nowManila.getTime() + 24 * 60 * 60 * 1000);
      const tomorrowStr = ManilaTime.toISODate(tomorrow);
      console.log(`🌙 6:00 PM - Processing reminders for tomorrow: ${tomorrowStr}`);

      // Manual Schedules Reminder
      const { data: regularSchedules } = await supabase
        .from('collection_schedules')
        .select('*')
        .eq('status', 'scheduled')
        .ilike('scheduled_date', `${tomorrowStr}%`);

      if (regularSchedules) {
        for (const s of regularSchedules) {
          await supabase.functions.invoke('send-push-v2', {
            body: {
              title: '📅 Collection Reminder',
              body: `Reminder: Waste collection in ${s.zone} is scheduled for tomorrow.`,
              type: 'reminder',
              barangay: s.zone
            }
          });
        }
      }
    }

    // --- 2. "STARTING NOW" ALERTS (ROBUST WINDOW) ---
    
    // A. Manual/One-time Schedules
    const { data: manualSchedules } = await supabase
      .from('collection_schedules')
      .select('*')
      .eq('status', 'scheduled')
      .ilike('scheduled_date', `${todayStr}%`);

    if (manualSchedules) {
      for (const s of manualSchedules) {
        // Extract time from ISO string or use scheduled_time column if it exists
        // Here we assume the date object contains the time info
        const sTime = ManilaTime.toHHMM(new Date(new Date(s.scheduled_date).getTime() + (8 * 60 * 60 * 1000)));
        
        if (isWithinWindow(sTime, timeStr)) {
          await processAlert(supabase, s.zone, sTime, todayStr, `manual_${s.id}`);
        }
      }
    }

    // B. Recurring Schedules (area_schedules)
    const dayName = nowManila.toLocaleString('en-US', { weekday: 'long', timeZone: 'UTC' }).toLowerCase();
    
    const { data: recurringSchedules } = await supabase
      .from('area_schedules')
      .select('*')
      .contains('days', [dayName]);

    if (recurringSchedules) {
      for (const s of recurringSchedules) {
        if (s.time && isWithinWindow(s.time, timeStr)) {
          await processAlert(supabase, s.area, s.time, todayStr, `recurring_${s.id}`);
        }
      }
    }

    return new Response(JSON.stringify({ success: true, processed_at: timeStr }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    const error = err as Error;
    console.error('💥 Error in check-schedules:', error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

/**
 * Handles the logic for sending a "Starting Now" alert and recording it in history.
 */
async function processAlert(supabase: any, barangay: string, schedTime: string, dateStr: string, uniqueRef: string) {
  // Deduplication check: Have we sent this specific alert already today?
  // We use the notification message + barangay + date + TIME to check.
  const dRef = `starting_now_${barangay}_${dateStr}_${schedTime}`;
  
  const { data: existing } = await supabase
    .from('user_notifications')
    .select('id')
    .eq('barangay', barangay)
    .eq('metadata->>dedup_key', dRef)
    .limit(1);

  if (existing && existing.length > 0) {
    console.log(`ℹ️ Skipping duplicate alert for ${barangay} at ${schedTime} (ID: ${uniqueRef}). Already sent.`);
    return;
  }

  console.log(`🚀 Triggering alert for ${barangay} scheduled at ${schedTime} (Reference: ${uniqueRef})`);

  // 1. Find Residents
  const { data: residents } = await supabase
    .from('profiles')
    .select('id')
    .eq('role', 'resident')
    .ilike('barangay', `%${barangay}%`);

  if (residents && residents.length > 0) {
    for (const r of residents) {
      // 2. Send Push
      await supabase.functions.invoke('send-push-v2', {
        body: {
          resident_id: r.id,
          title: '🚛 Collection Starting Now',
          body: `Waste collection in ${barangay} is starting now! (Scheduled at ${schedTime})`,
          type: 'alert'
        }
      });

      // 3. Log to History
      await supabase.from('user_notifications').insert({
        user_id: r.id,
        title: '🚛 Collection Starting Now',
        message: `Waste collection in ${barangay} is starting now! (Scheduled at ${schedTime})`,
        type: 'alert',
        barangay: barangay,
        metadata: { dedup_key: dRef, sched_time: schedTime, source: uniqueRef }
      });
    }
  }
}
