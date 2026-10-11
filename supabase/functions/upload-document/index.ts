import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { fileName, fileBase64, bucketName, contentType } = await req.json()

    if (!fileName || !fileBase64 || !bucketName) {
      throw new Error('Missing required upload parameters')
    }

    // Initialize Supabase admin client using the Service Role Key.
    // This BYPASSES all RLS and ownership errors on storage.objects.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: { persistSession: false }
      }
    )

    // 1. Auto-create the bucket if it's missing (Fixes the 404 Bucket Not Found)
    const { data: buckets, error: listError } = await supabaseAdmin.storage.listBuckets()
    if (listError) throw listError

    const bucketExists = buckets?.find((b: any) => b.name === bucketName)
    if (!bucketExists) {
      const { error: createError } = await supabaseAdmin.storage.createBucket(bucketName, { public: true })
      if (createError) console.error("Bucket creation note:", createError) // Might fail if it already exists but isn't cached
    }

    // 2. Decode the Base64 file
    const binaryString = atob(fileBase64)
    const fileBytes = new Uint8Array(binaryString.length)
    for (let i = 0; i < binaryString.length; i++) {
      fileBytes[i] = binaryString.charCodeAt(i)
    }

    // 3. Upload file directly bypassing RLS permissions
    const { data: uploadData, error: uploadError } = await supabaseAdmin.storage
      .from(bucketName)
      .upload(fileName, fileBytes, {
        contentType: contentType || 'image/jpeg',
        upsert: true
      })

    if (uploadError) throw uploadError

    // 4. Retrieve Public URL
    const { data: urlData } = supabaseAdmin.storage.from(bucketName).getPublicUrl(fileName)

    return new Response(
      JSON.stringify({ url: urlData.publicUrl }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
