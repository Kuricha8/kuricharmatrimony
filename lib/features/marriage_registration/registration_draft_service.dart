import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RegistrationDraftService {
  static Future<void> generateAndViewDraft({
    required String groomName,
    required String brideName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'FORM NO. I',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    '[See Rule 6(1)]',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'MEMORANDUM FOR REGISTRATION OF MARRIAGE',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 32),

                // Form Fields
                _buildField(
                  '1. Date of Marriage',
                  '..........................................',
                ),
                _buildField(
                  '2. Place of Marriage',
                  '..........................................',
                ),

                pw.SizedBox(height: 24),
                pw.Text(
                  '3. Details of Parties to the Marriage:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),

                // Table for Husband/Wife
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  data: [
                    ['Details', 'Husband', 'Wife'],
                    ['(a) Name', groomName, brideName],
                    [
                      '(b) Date of Birth/Age',
                      '....................',
                      '....................',
                    ],
                    [
                      '(c) Religion/Caste',
                      'Hindu / Kurichiyar',
                      'Hindu / Kurichiyar',
                    ],
                    [
                      '(d) Name of Father',
                      '....................',
                      '....................',
                    ],
                    [
                      '(e) Name of Mother',
                      '....................',
                      '....................',
                    ],
                    [
                      '(f) Address',
                      '....................\n....................',
                      '....................\n....................',
                    ],
                    ['(g) Signature', '', ''],
                  ],
                ),

                pw.SizedBox(height: 32),
                pw.Text(
                  '4. Details of Witnesses:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),

                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  data: [
                    ['Sl No.', 'Name and Address', 'Signature'],
                    [
                      '1.',
                      '..................................................\n..................................................',
                      '',
                    ],
                    [
                      '2.',
                      '..................................................\n..................................................',
                      '',
                    ],
                  ],
                ),

                pw.SizedBox(height: 48),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: ........................'),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          '................................................',
                        ),
                        pw.Text('Signature of the Local Registrar'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Marriage_Registration_Draft_${groomName}_$brideName.pdf',
    );
  }

  static pw.Widget _buildField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 2, child: pw.Text(label)),
          pw.Expanded(flex: 3, child: pw.Text(value)),
        ],
      ),
    );
  }
}
