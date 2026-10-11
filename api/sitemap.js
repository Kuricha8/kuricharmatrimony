module.exports = async function handler(req, res) {
  const supabaseUrl = process.env.supabase_url;
  const supabaseKey = process.env.supabase_anon_key;

  // Get current Vercel URL dynamically
  const host = req.headers.host || process.env.VERCEL_URL || 'pcm-wayanad-portal.surge.sh';
  const protocol = host.includes('localhost') ? 'http' : 'https';
  const baseUrl = `${protocol}://${host}`;

  try {
    // Query active approved profiles directly from Supabase REST API
    const fetchUrl = `${supabaseUrl}/rest/v1/profiles?is_profile_hidden=eq.false&account_status=eq.approved&is_banned=eq.false&select=id`;
    const response = await fetch(fetchUrl, {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`
      }
    });

    let profiles = [];
    if (response.ok) {
      profiles = await response.json();
    } else {
      console.error('Supabase sitemap fetch failed status:', response.status);
    }

    // Build the XML sitemap
    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

    // Add home page
    xml += '  <url>\n';
    xml += `    <loc>${baseUrl}/</loc>\n`;
    xml += '    <changefreq>daily</changefreq>\n';
    xml += '    <priority>1.0</priority>\n';
    xml += '  </url>\n';

    // Add profile pages
    profiles.forEach(p => {
      xml += '  <url>\n';
      xml += `    <loc>${baseUrl}/profile/km-2026-${p.id}</loc>\n`;
      xml += '    <changefreq>weekly</changefreq>\n';
      xml += '    <priority>0.8</priority>\n';
      xml += '  </url>\n';
    });

    xml += '</urlset>\n';

    res.setHeader('Content-Type', 'application/xml');
    return res.status(200).send(xml);
  } catch (err) {
    console.error('Sitemap API generation error:', err);
    // Return minimal sitemap on error
    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';
    xml += '  <url>\n';
    xml += `    <loc>${baseUrl}/</loc>\n`;
    xml += '    <priority>1.0</priority>\n';
    xml += '  </url>\n';
    xml += '</urlset>\n';
    res.setHeader('Content-Type', 'application/xml');
    return res.status(200).send(xml);
  }
};
