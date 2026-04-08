
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31'; // Anon key

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function checkRecords() {
    console.log('🔍 Checking for Mahayag/Visitors in database...');

    // 1. Check collection_schedules
    const { data: collectionSchedules, error: collError } = await supabase
        .from('collection_schedules')
        .select('*');
    
    if (collError) {
        console.error('Error fetching collection_schedules:', collError);
    } else {
        const matches = collectionSchedules.filter(s => 
            (s.zone || '').toLowerCase().includes('mahayag') || 
            (s.zone || '').toLowerCase().includes('visitors') ||
            (s.description || '').toLowerCase().includes('mahayag') ||
            (s.description || '').toLowerCase().includes('visitors')
        );
        console.log(`Found ${matches.length} matches in collection_schedules:`);
        matches.forEach(m => console.log(` - ID: ${m.id}, Zone: ${m.zone}, Name: ${m.name}, Desc: ${m.description}`));
    }

    // 2. Check area_schedules (fixed schedules)
    const { data: areaSchedules, error: areaError } = await supabase
        .from('area_schedules')
        .select('*');
    
    if (areaError) {
        console.error('Error fetching area_schedules:', areaError);
    } else {
        const matches = areaSchedules.filter(s => 
            (s.area || '').toLowerCase().includes('mahayag') || 
            (s.area || '').toLowerCase().includes('visitors') ||
            (s.scheduleName || '').toLowerCase().includes('mahayag') ||
            (s.scheduleName || '').toLowerCase().includes('visitors')
        );
        console.log(`Found ${matches.length} matches in area_schedules:`);
        matches.forEach(m => console.log(` - ID: ${m.id}, Area: ${m.area}, Name: ${m.scheduleName}`));
    }
}

checkRecords();
