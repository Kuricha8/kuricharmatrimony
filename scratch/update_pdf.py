# -*- coding: utf-8 -*-
import os

dart_code = r'''import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

class AdminBiodataPdfService {
  static final AdminBiodataPdfService instance = AdminBiodataPdfService._internal();
  AdminBiodataPdfService._internal();

  static const String adminAttribution = "Issued by Admin: Rineesh";
  static const String appHeaderTitle = "KURICHIYAR MATRIMONY";
  static const String appSubtitle = "OFFICIAL MATRIMONIAL CANDIDATE BIODATA";

  /// Generates A4 Official Matrimonial Biodata PDF and opens instant preview/download
  Future<void> generateAndPreviewPdf(BuildContext context, UserProfile profile) async {
    try {
      final pdf = pw.Document();
      final String timestampStr = DateFormat('dd/MM/yyyy, hh:mm a').format(DateTime.now());

      // 0. Load Unicode Font (Roboto) for crisp layout and zero font glitches
      pw.ThemeData? customTheme;
      try {
        final font = await PdfGoogleFonts.roboto().timeout(const Duration(seconds: 3));
        final boldFont = await PdfGoogleFonts.robotoBold().timeout(const Duration(seconds: 3));
        customTheme = pw.ThemeData.withFont(base: font, bold: boldFont);
      } catch (e) {
        debugPrint('PdfGoogleFonts fallback to default: $e');
      }

      // 1. Official App Logo Loading (Asset -> Network -> Elegant Fallback)
      pw.MemoryImage? logoImage;
      try {
        Uint8List? logoBytes;
        for (final assetPath in [
          'assets/images/logo.png',
          'assets/images/app_logo.png',
          'assets/images/logo_kym.png',
        ]) {
          try {
            final byteData = await rootBundle.load(assetPath);
            logoBytes = byteData.buffer.asUint8List();
            if (logoBytes.isNotEmpty) break;
          } catch (_) {}
        }

        // If local asset bundle failed, try remote web asset with short timeout
        if (logoBytes == null || logoBytes.isEmpty) {
          try {
            final res = await http
                .get(Uri.parse('https://kuricharmatrimony.vercel.app/icons/Icon-192.png'))
                .timeout(const Duration(seconds: 2));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              logoBytes = res.bodyBytes;
            }
          } catch (_) {}
        }

        if (logoBytes != null && logoBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(logoBytes);
        }
      } catch (e) {
        debugPrint('Logo load error for PDF: $e');
      }

      // 2. Candidate Photo Loading
      pw.ImageProvider? candidateImage;
      if (profile.photoUrl != null && profile.photoUrl!.trim().isNotEmpty) {
        try {
          final netImage = await networkImage(profile.photoUrl!);
          candidateImage = netImage;
        } catch (e) {
          debugPrint('Error loading profile image for PDF: $e');
        }
      }

      // Clean & Map all Profile Fields
      final String cleanName = _cleanPdfText(profile.fullName, defaultVal: 'Candidate Member');
      final String cleanGender = _cleanPdfText(profile.gender, defaultVal: 'Not specified');
      final String cleanAge = profile.computedAge.isNotEmpty && profile.computedAge != 'N/A'
          ? '${profile.computedAge} Years'
          : 'Not specified';
      final String cleanDob = profile.dobFormatted;
      final String cleanMarital = _cleanMaritalStatus(profile.maritalStatus);
      final String cleanHeight = profile.height != null && profile.height!.trim().isNotEmpty && profile.height != 'Not specified'
          ? '${profile.height!.replaceAll(RegExp(r'[^0-9]'), '')} cm'
          : 'Not specified';
      final String cleanDistrict = _cleanPdfText(profile.district, defaultVal: 'Wayanad');
      final String cleanNativePlace = _cleanPdfText(profile.nativePlace ?? profile.panchayath, defaultVal: cleanDistrict);

      // Section 1: Lineage
      final String cleanTharavadu = _cleanPdfText(profile.tharavadu, defaultVal: 'Not specified');
      final String cleanMotherTharavadu = _cleanPdfText(profile.motherTharavadu, defaultVal: 'Not specified');
      final String cleanFatherTharavadu = _cleanPdfText(profile.fatherTharavadu, defaultVal: 'Not specified');
      final String cleanGothram = _cleanPdfText(profile.gothram, defaultVal: 'Panthi / Bandhu Gotra');
      final String cleanKulam = _cleanPdfText(profile.kulam, defaultVal: 'Traditional Kurichiyar');

      // Section 2: Education & Career
      final String cleanEducation = _cleanPdfText(profile.education, defaultVal: 'Not specified');
      final String cleanOccupation = _cleanPdfText(profile.occupation, defaultVal: 'Not specified');
      final String cleanWorkplace = _cleanPdfText(profile.workplace, defaultVal: 'Not specified');
      final String cleanIncome = _cleanPdfText(profile.annualIncome, defaultVal: 'Not specified');

      // Section 3: Family
      final String cleanFatherName = _cleanPdfText(profile.fatherName, defaultVal: 'Not specified');
      final String cleanMotherName = _cleanPdfText(profile.motherName, defaultVal: 'Not specified');
      final String cleanHouseName = _cleanPdfText(profile.houseName, defaultVal: 'Not specified');
      final String cleanSiblings = _cleanPdfText(profile.siblings, defaultVal: 'Not specified');

      // Section 4: Contact & Residential
      final String cleanPhone = _cleanPdfText(profile.phone, defaultVal: 'Not specified');
      final String cleanAltPhone = _cleanPdfText(profile.alternativePhone, defaultVal: 'Not specified');
      final String cleanEmail = _cleanPdfText(profile.email, defaultVal: 'Not specified');
      final String cleanAddress = _cleanPdfText(profile.address, defaultVal: '$cleanHouseName, $cleanNativePlace, $cleanDistrict');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: customTheme,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── 1. HEADER (Dark Banner with Official Logo, Title & Admin Seal) ──
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1E1B2E'), // Deep Indigo Banner
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 1.2), // Gold Border
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Logo + Title block
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 38,
                              height: 38,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 1.5),
                              ),
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.ClipOval(
                                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                              ),
                            )
                          else
                            pw.Container(
                              width: 38,
                              height: 38,
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#D4AF37'),
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'KM',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1E1B2E'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                appHeaderTitle,
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                appSubtitle,
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#FFD700'), // Gold
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Admin Verification Stamp on Top Right
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#D32F2F'), // Official Crimson Red
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                              border: pw.Border.all(color: PdfColors.white, width: 0.8),
                            ),
                            child: pw.Text(
                              adminAttribution,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Verified Record: $timestampStr',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 14),

                // ── 2. CANDIDATE OVERVIEW CARD (Photo & Clean Metadata) ──
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FBFBFC'),
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Photo
                      pw.Container(
                        width: 82,
                        height: 98,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColor.fromHex('#D4AF37'), width: 1.2),
                        ),
                        child: candidateImage != null
                            ? pw.ClipRRect(
                                horizontalRadius: 5,
                                verticalRadius: 5,
                                child: pw.Image(candidateImage, fit: pw.BoxFit.cover),
                              )
                            : pw.Center(
                                child: pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text('PHOTO', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                    pw.Text('VERIFIED', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                                  ],
                                ),
                              ),
                      ),
                      pw.SizedBox(width: 14),
                      // Core Highlights
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    cleanName.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 15,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColor.fromHex('#1E1B2E'),
                                    ),
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.green100,
                                    borderRadius: pw.BorderRadius.circular(4),
                                    border: pw.Border.all(color: PdfColors.green700, width: 0.5),
                                  ),
                                  child: pw.Text(
                                    'APPROVED',
                                    style: pw.TextStyle(
                                      color: PdfColors.green900,
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            _pdfMetaRow('Gender & Age:', 'Gender: $cleanGender | Age: $cleanAge (DOB: $cleanDob)'),
                            _pdfMetaRow('Physical Status:', 'Height: $cleanHeight | Marital Status: $cleanMarital'),
                            _pdfMetaRow('Community:', 'Hindu / Kurichiyar Tribal Heritage (ST)'),
                            _pdfMetaRow('Native Place:', '$cleanNativePlace, $cleanDistrict'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // ── 3. SECTION 1: LINEAGE & KINSHIP ──
                _pdfSectionTitle('1. LINEAGE & KINSHIP DETAILS'),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FAFAFA'),
                    border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Primary Tharavadu', cleanTharavadu)),
                          pw.Expanded(child: _pdfFieldItem("Mother's Tharavadu (Ammavazhi)", cleanMotherTharavadu)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem("Father's Tharavadu", cleanFatherTharavadu)),
                          pw.Expanded(child: _pdfFieldItem('Moiety / Clan Group (Gotra)', cleanGothram)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Sub-lineage / Kulam', cleanKulam)),
                          pw.Expanded(child: _pdfFieldItem('Kinship Exogamy Status', 'Traditional Exogamous Clan Match')),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 11),

                // ── 4. SECTION 2: QUALIFICATION & CAREER ──
                _pdfSectionTitle('2. QUALIFICATION & CAREER'),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FAFAFA'),
                    border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Highest Education / Degree', cleanEducation)),
                          pw.Expanded(child: _pdfFieldItem('Job Role / Designation', cleanOccupation)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Company / Workplace', cleanWorkplace)),
                          pw.Expanded(child: _pdfFieldItem('Annual Income', cleanIncome)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 11),

                // ── 5. SECTION 3: FAMILY DETAILS ──
                _pdfSectionTitle('3. FAMILY DETAILS'),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FAFAFA'),
                    border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem("Father's Name", cleanFatherName)),
                          pw.Expanded(child: _pdfFieldItem("Mother's Name", cleanMotherName)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('House Name', cleanHouseName)),
                          pw.Expanded(child: _pdfFieldItem('Siblings Details', cleanSiblings)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Native Place / Panchayath', cleanNativePlace)),
                          pw.Expanded(child: _pdfFieldItem('District', cleanDistrict)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 11),

                // ── 6. SECTION 4: CONTACT DETAILS ──
                _pdfSectionTitle('4. CONTACT & RESIDENTIAL DETAILS'),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F7FA'),
                    border: pw.Border.all(color: PdfColor.fromHex('#B0BEC5')),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Phone Number', cleanPhone)),
                          pw.Expanded(child: _pdfFieldItem('Alternative Contact', cleanAltPhone)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _pdfFieldItem('Email Address', cleanEmail)),
                          pw.Expanded(child: _pdfFieldItem('Residential Address', cleanAddress)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ── 7. FOOTER / VERIFICATION BAR ──
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F5F5'),
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Official Matrimonial Record • Verified & Digitally Certified by Kurichiyar Matrimony Admin Console',
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'This document is strictly issued for verified matrimonial proposal viewing. Unauthorized duplication is prohibited.',
                            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#1E1B2E'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          adminAttribution,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#FFD700'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Open Instant Printing / Download / Share Preview modal
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${cleanName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_Biodata.pdf',
      );
    } catch (e) {
      debugPrint('Error generating Biodata PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Generation Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Share Biodata via WhatsApp
  static Future<void> shareToWhatsApp(BuildContext context, UserProfile profile) async {
    try {
      final String phone = profile.phone ?? '';
      final String text = '''
*KURICHIYAR MATRIMONY OFFICIAL BIODATA*
Issued by: *Admin: Rineesh*

*Candidate Profile Details:*
- *Name:* ${profile.fullName}
- *Gender & Age:* ${profile.gender} | ${profile.computedAge} Years (DOB: ${profile.dobFormatted})
- *Height & Status:* ${profile.height ?? 'Not specified'} | ${profile.maritalStatus}
- *Primary Tharavadu:* ${profile.tharavadu ?? 'Not specified'}
- *Mother's Tharavadu (Ammavazhi):* ${profile.motherTharavadu ?? 'Not specified'}
- *Father's Tharavadu:* ${profile.fatherTharavadu ?? 'Not specified'}
- *Moiety / Gotra:* ${profile.gothram ?? 'Kurichiyar Gotra'}
- *Sub-lineage / Kulam:* ${profile.kulam ?? 'Not specified'}
- *Highest Education:* ${profile.education ?? 'Not specified'}
- *Job Role / Profession:* ${profile.occupation ?? 'Not specified'}
- *Workplace:* ${profile.workplace ?? 'Not specified'}
- *Annual Income:* ${profile.annualIncome ?? 'Not specified'}
- *Native Place:* ${profile.nativePlace ?? profile.district ?? 'Wayanad'}
- *Father's Name:* ${profile.fatherName}
- *Mother's Name:* ${profile.motherName}
- *House Name:* ${profile.houseName}
- *Contact:* ${profile.phone ?? 'Not specified'} (Alt: ${profile.alternativePhone ?? 'Not specified'})

_Official PDF Biodata generated via Kurichiyar Matrimony Admin Console_
''';

      final Uri url = Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'\D'), '')}?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final Uri generalUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
        await launchUrl(generalUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
    }
  }

  static String _cleanMaritalStatus(String? input) {
    if (input == null || input.trim().isEmpty) return 'Never Married / Single';
    final lower = input.toLowerCase();
    if (lower.contains('divorce')) return 'Divorced';
    if (lower.contains('widow')) return 'Widowed';
    if (lower.contains('never') || lower.contains('single') || lower.contains('first') || lower.contains('unmarried')) {
      return 'Never Married / Single';
    }
    return _cleanPdfText(input, defaultVal: 'Never Married / Single');
  }

  static String _cleanPdfText(String? input, {String defaultVal = 'Not specified'}) {
    if (input == null || input.trim().isEmpty) return defaultVal;
    final trimmed = input.trim();
    if (trimmed.toLowerCase() == 'null' || trimmed.toLowerCase() == 'n/a') return defaultVal;

    // Strip unrendered non-ASCII byte sequences that cause font glitches, and clean up empty parentheses
    final cleaned = trimmed
        .replaceAll(RegExp(r'\s*\(\s*/?\s*\)\s*'), ' ')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.isNotEmpty && cleaned != defaultVal ? cleaned : defaultVal;
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 12,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#B71C1C'), // Crimson Bar
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E1B2E'),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 96,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E1B2E'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFieldItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#212121'),
          ),
        ),
      ],
    );
  }
}
'''

target_path = r'E:\ADMIN APP\lib\services\admin_biodata_pdf_service.dart'
with open(target_path, 'w', encoding='utf-8') as f:
    f.write(dart_code)
print(f'Wrote {len(dart_code)} bytes to {target_path}')
