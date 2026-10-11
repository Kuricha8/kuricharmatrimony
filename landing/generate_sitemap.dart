// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  final baseUrl = 'https://pcm-wayanad-portal.surge.sh';

  print('Generating sitemap.xml for $baseUrl...');

  try {
    final client = HttpClient();
    final uri = Uri.parse('$supabaseUrl/rest/v1/profiles?select=id,updated_at&is_profile_hidden=eq.false&account_status=eq.approved&is_banned=eq.false');
    final request = await client.getUrl(uri);
    request.headers.add('apikey', supabaseKey);
    request.headers.add('Authorization', 'Bearer $supabaseKey');

    final response = await request.close();
    if (response.statusCode != 200) {
      print('Failed to fetch profiles: ${response.statusCode}');
      final body = await response.transform(utf8.decoder).join();
      print(body);
      exit(1);
    }

    final body = await response.transform(utf8.decoder).join();
    final List<dynamic> profiles = jsonDecode(body);
    print('Fetched ${profiles.length} public profiles.');

    final sitemapContent = StringBuffer();
    sitemapContent.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sitemapContent.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    // Add home page
    sitemapContent.writeln('  <url>');
    sitemapContent.writeln('    <loc>$baseUrl/</loc>');
    sitemapContent.writeln('    <changefreq>daily</changefreq>');
    sitemapContent.writeln('    <priority>1.0</priority>');
    sitemapContent.writeln('  </url>');

    // Add each profile page
    for (var profile in profiles) {
      final id = profile['id'];
      final updatedAtStr = profile['updated_at'] as String?;
      final lastmod = updatedAtStr != null ? updatedAtStr.substring(0, 10) : DateTime.now().toIso8601String().substring(0, 10);
      sitemapContent.writeln('  <url>');
      sitemapContent.writeln('    <loc>$baseUrl/profile/km-2026-$id</loc>');
      sitemapContent.writeln('    <lastmod>$lastmod</lastmod>');
      sitemapContent.writeln('    <changefreq>weekly</changefreq>');
      sitemapContent.writeln('    <priority>0.8</priority>');
      sitemapContent.writeln('  </url>');
    }

    sitemapContent.writeln('</urlset>');

    final outputFile = File('landing/sitemap.xml');
    await outputFile.writeAsString(sitemapContent.toString());
    print('Successfully generated sitemap.xml at ${outputFile.path}');
  } catch (e) {
    print('Error generating sitemap: $e');
    exit(1);
  }
}
