const fs = require('node:fs');
const path = require('node:path');

module.exports = async function handler(req, res) {
  const profileId = req.query.id || '';

  // Get credentials from environment variables
  const supabaseUrl = process.env.supabase_url;
  const supabaseKey = process.env.supabase_anon_key;

  // Get current Vercel URL dynamically
  const host = req.headers.host || process.env.VERCEL_URL || 'pcm-wayanad-portal.surge.sh';
  const protocol = host.includes('localhost') ? 'http' : 'https';
  const baseUrl = `${protocol}://${host}`;

  let htmlPath = path.join(process.cwd(), 'landing', 'index.html');
  
  // Read index.html template
  let html = '';
  try {
    html = fs.readFileSync(htmlPath, 'utf8');
  } catch (err) {
    console.error('Error reading template file:', err);
    return res.status(500).send('Error reading template files');
  }

  if (!profileId) {
    // Return standard template
    return res.send(html);
  }

  const cleanId = profileId.replace('km-2026-', '');

  try {
    // Fetch profile details directly from Supabase REST API using native fetch
    const fetchUrl = `${supabaseUrl}/rest/v1/profiles?id=eq.${cleanId}&select=name,age,father_tharavadu,photo_url,gender,job`;
    const response = await fetch(fetchUrl, {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`
      }
    });

    if (!response.ok) {
      console.error('Supabase fetch failed status:', response.status);
      return res.send(html);
    }

    const records = await response.json();
    const data = records[0];

    if (!data) {
      return res.send(html);
    }

    const userName = data.name || 'User';
    const taravadName = data.father_tharavadu || 'Kurichiyar';
    
    // Set dynamic SEO meta payloads
    const pageTitle = `${userName} | Kurichiyar Matrimony`;
    const pageDesc = `Find alliance for ${userName} from ${taravadName} family lineage on Kurichiyar Matrimony.`;
    const pageKeywords = `Kurichiyar, Matrimony, ${userName}, ${taravadName}, Wayanad marriage`;
    const pageUrl = `${baseUrl}/profile/km-2026-${cleanId}`;
    const photoUrl = data.photo_url || '';

    // Replace Title
    html = html.replace(/<title>.*?<\/title>/gi, `<title>${pageTitle}</title>`);

    // Replace or insert Meta Tags (Description, Keywords)
    html = html.replace(/<meta name="description" content=".*?"\/?>/gi, `<meta name="description" content="${pageDesc}">`);
    html = html.replace(/<meta name="keywords" content=".*?"\/?>/gi, `<meta name="keywords" content="${pageKeywords}">`);

    // OpenGraph
    html = html.replace(/<meta property="og:title" content=".*?"\/?>/gi, `<meta property="og:title" content="${pageTitle}">`);
    html = html.replace(/<meta property="og:description" content=".*?"\/?>/gi, `<meta property="og:description" content="${pageDesc}">`);
    html = html.replace(/<meta property="og:url" content=".*?"\/?>/gi, `<meta property="og:url" content="${pageUrl}">`);
    html = html.replace(/<meta property="og:image" content=".*?"\/?>/gi, `<meta property="og:image" content="${photoUrl}">`);

    // Twitter
    html = html.replace(/<meta name="twitter:title" content=".*?"\/?>/gi, `<meta name="twitter:title" content="${pageTitle}">`);
    html = html.replace(/<meta name="twitter:description" content=".*?"\/?>/gi, `<meta name="twitter:description" content="${pageDesc}">`);
    html = html.replace(/<meta name="twitter:image" content=".*?"\/?>/gi, `<meta name="twitter:image" content="${photoUrl}">`);

    // Canonical link
    html = html.replace(/<link id="canonicalUrl" rel="canonical" href=".*?"\/?>/gi, `<link id="canonicalUrl" rel="canonical" href="${pageUrl}">`);

    // Inject structured JSON-LD Person schema inside the script tag id="structuredData"
    const jsonLd = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name": userName,
      "age": data.age,
      "gender": data.gender || "unknown",
      "jobTitle": data.job || "N/A",
      "memberOf": {
        "@type": "Organization",
        "name": "Kurichiyar Community"
      },
      "description": pageDesc,
      "image": photoUrl,
      "url": pageUrl
    };

    html = html.replace(
      /<script type="application\/ld\+json" id="structuredData"><\/script>/gi,
      `<script type="application/ld+json" id="structuredData">${JSON.stringify(jsonLd, null, 2)}</script>`
    );

    res.setHeader('Content-Type', 'text/html');
    return res.send(html);
  } catch (err) {
    console.error('Serverless SEO rendering error:', err);
    return res.send(html);
  }
};
