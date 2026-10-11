import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/models.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndDownloadAgreementPdf({
    required UserProfile currentUser,
    required UserProfile targetProfile,
    required String agreementId,
  }) async {
    final pdf = pw.Document();

    // Try to load the logo
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_kym.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Ignore if logo fails to load
    }

    final bride = currentUser.gender == Gender.female
        ? currentUser
        : targetProfile;
    final groom = currentUser.gender == Gender.male
        ? currentUser
        : targetProfile;

    // We can't load network images synchronously in pdf generation easily without http package.
    // So for the PDF, we will use placeholders or text if network images aren't pre-fetched.
    // For simplicity, we just use their names and placeholders.

    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // HEADER
              if (logoImage != null)
                pw.Container(height: 60, child: pw.Image(logoImage))
              else
                pw.Text(
                  'KURICHIYAR MATRIMONY',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              pw.SizedBox(height: 16),
              pw.Text(
                'MUTUAL MARRIAGE INTENT BOND',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Agreement ID: $agreementId',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Text(
                'Date of Activation: $dateStr',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),

              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 24),

              // BODY: DUAL PROFILES
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  // Bride
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.pink50,
                          border: pw.Border.all(
                            color: PdfColors.amber,
                            width: 2,
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'BRIDE',
                            style: pw.TextStyle(
                              color: PdfColors.pink,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        bride.name,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        bride.email,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),

                  pw.Text(
                    '&',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.pink,
                    ),
                  ),

                  // Groom
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.blue50,
                          border: pw.Border.all(
                            color: PdfColors.amber,
                            width: 2,
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'GROOM',
                            style: pw.TextStyle(
                              color: PdfColors.blue,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        groom.name,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        groom.email,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 32),

              // TERMS
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MARRIAGE ASSURANCE POLICY',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'By agreeing and depositing the Assurance Fee of ₹7,000 per party, both users enter into a mutual marriage intent contract.',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildPdfBullet(
                      'If the wedding is called off by Party A without valid legal grounds, Party A\'s deposit is forfeited.',
                    ),
                    _buildPdfBullet(
                      'Party B (the affected party) will receive a refund of their own ₹7,000 plus an additional ₹2,000 compensation from the forfeited amount (Total ₹9,000 received).',
                    ),
                    _buildPdfBullet(
                      'The remaining ₹5,000 will be retained by Kurichiyar Matrimony as processing and service charges.',
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // FOOTER
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AUTHORIZED & WITNESSED BY ADMIN: RANEESH',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Kurichiyar Matrimony Official Record',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 80,
                    height: 40,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red900, width: 2),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'OFFICIAL\nSTAMP',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.red900,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Mutual_Agreement_$agreementId.pdf',
    );
  }

  static pw.Widget _buildPdfBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
