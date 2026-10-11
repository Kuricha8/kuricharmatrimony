import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Use Service Role Key to bypass RLS and perform admin database tasks
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey)
  
  // Call the database keep-alive and purge function
  const { data, error } = await supabase.rpc('keep_alive_and_purge')
  
  if (error) {
    console.error("Keep-Alive Error:", error)
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" } 
    })
  }
  
  return new Response(JSON.stringify({ success: true, result: data }), { 
    status: 200, 
    headers: { "Content-Type": "application/json" } 
  })
})
