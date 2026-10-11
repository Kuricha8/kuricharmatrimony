const { Client } = require('pg');

const connectionString = process.env.DATABASE_URL || "postgresql://user:password@localhost:5432/db";

async function run() {
  const client = new Client({ connectionString });
  await client.connect();
  console.log("Connected to PostgreSQL (Neon) successfully.");

  try {
    // 1. Check if the table kurichiyar_profiles exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'kurichiyar_profiles'
      );
    `);
    
    const tableExists = tableCheck.rows[0].exists;
    console.log(`Table 'kurichiyar_profiles' exists: ${tableExists}`);

    if (tableExists) {
      // 2. Query conflicting profiles
      const selectRes = await client.query(`
        SELECT id, full_name, phone, email, registration_status, account_status 
        FROM public.kurichiyar_profiles 
        WHERE phone LIKE '%8606415174%' 
        OR guardian_phone LIKE '%8606415174%' 
        OR public_display_number LIKE '%8606415174%';
      `);
      
      console.log(`Found ${selectRes.rows.length} conflicting profile(s):`, selectRes.rows);

      if (selectRes.rows.length > 0) {
        // 3. Delete conflicting profiles
        const deleteRes = await client.query(`
          DELETE FROM public.kurichiyar_profiles 
          WHERE phone LIKE '%8606415174%' 
          OR guardian_phone LIKE '%8606415174%' 
          OR public_display_number LIKE '%8606415174%';
        `);
        console.log(`Deleted ${deleteRes.rowCount} profile record(s) from kurichiyar_profiles.`);
      } else {
        console.log("No profile record found in kurichiyar_profiles with phone 8606415174.");
      }
    }
  } catch (err) {
    console.error("Error during database cleanup:", err);
  } finally {
    await client.end();
  }
}

run();
