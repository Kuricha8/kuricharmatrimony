import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PdfService {
  static Future<void> generateAndPrintAuditPdf(
    Map<String, dynamic> userProfile,
  ) async {
    final pdf = pw.Document();

    // Fetch device info for audit log
    String deviceInfo = 'Unknown Device';
    try {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        deviceInfo =
            '${info.brand} ${info.model} (Android ${info.version.release})';
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        deviceInfo = '${info.name} ${info.systemName} ${info.systemVersion}';
      }
    } catch (e) {
      deviceInfo = 'Error fetching device info: $e';
    }

    final createdAtRaw = userProfile['created_at'] as String?;
    final registeredAt = createdAtRaw != null
        ? DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(DateTime.parse(createdAtRaw).toLocal())
        : 'Unknown Time';

    final clickTimestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    // Basic fields
    final String name = userProfile['name']?.toString() ?? 'N/A';
    final String email = userProfile['email']?.toString() ?? 'N/A';
    final String phone = userProfile['phone']?.toString() ?? 'N/A';
    final String gender = userProfile['gender']?.toString() ?? 'N/A';
    final String role = userProfile['role']?.toString() ?? 'N/A';
    final String status =
        userProfile['account_status']?.toString() ??
        userProfile['registration_status']?.toString() ??
        'N/A';
    final String ipAddress =
        userProfile['registration_ip']?.toString() ?? '192.168.1.1 (Simulated)';

    // Additional Dummy Fields
    final String age = userProfile['age']?.toString() ?? 'N/A';
    final String location = userProfile['region']?.toString() ?? 'N/A';
    final String clan = userProfile['name'] == 'Test User (Dummy)'
        ? 'Test Clan 1'
        : 'N/A';
    if (userProfile['name'] == 'Test User (Dummy)') {
      deviceInfo = 'Android 14 / Emulator';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'KURICHIYAR MATRIMONY',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.Text(
                    'OFFICIAL AUDIT LOG',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Profile Info Section
            pw.Text(
              'USER PROFILE RECORD',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),

            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _buildTableRow('Full Name:', name),
                _buildTableRow('Age / Location:', '$age, $location'),
                _buildTableRow('Taravad / Clan:', clan),
                _buildTableRow('Email Address:', email),
                _buildTableRow('Phone Number:', phone),
                _buildTableRow('Gender:', gender),
                _buildTableRow('Role:', role),
                _buildTableRow('Account Status:', status),
              ],
            ),
            pw.SizedBox(height: 30),

            // Timestamps and Audit Info
            pw.Text(
              'SYSTEM METADATA & TIMESTAMPS',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                _buildTableRow('Registration Timestamp:', registeredAt),
                _buildTableRow('Registration IP Address:', ipAddress),
                _buildTableRow('Admin Device (Generated On):', deviceInfo),
              ],
            ),
            pw.SizedBox(height: 40),

            // Legal Consent Clause
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LEGAL CONSENT & AGREEMENT',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'This document serves as an official audit record confirming that the user has explicitly read, understood, and digitally signed the "Terms & Conditions" and "Privacy Policy" of Kurichiyar Matrimony.',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green100,
                          border: pw.Border.all(color: PdfColors.green700),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          'DIGITALLY ACCEPTED',
                          style: pw.TextStyle(
                            color: PdfColors.green800,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Verified via OTP sent to Registered Mobile Number: $phone',
                    style: pw.TextStyle(
                      color: PdfColors.grey800,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'User Email: $email',
                    style: pw.TextStyle(
                      color: PdfColors.grey800,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Consent Timestamp: $clickTimestamp',
                    style: pw.TextStyle(
                      color: PdfColors.grey800,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Trigger Print/Save dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'User_Audit_Log_${name.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Generates a PDF summary of the registration for WhatsApp verification.
  static Future<Uint8List> generateRegistrationPdf(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Registration Summary - Kurichiyar Matrimony',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    _buildSimpleTableRow(
                      'Name',
                      data['name']?.toString() ?? 'N/A',
                    ),
                    _buildSimpleTableRow(
                      'Phone',
                      data['phone']?.toString() ?? 'N/A',
                    ),
                    _buildSimpleTableRow(
                      'Gender',
                      data['gender']?.toString() ?? 'N/A',
                    ),
                    _buildSimpleTableRow(
                      'Father\'s Tharavadu',
                      data['fatherTharavadu']?.toString() ?? 'N/A',
                    ),
                    _buildSimpleTableRow(
                      'Mother\'s Tharavadu',
                      data['motherTharavadu']?.toString() ?? 'N/A',
                    ),
                    _buildSimpleTableRow(
                      'Generated On',
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Note: This is a system-generated document for verification purposes.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildSimpleTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value)),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
