import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'document_vault_widget.dart';
import 'registration_draft_service.dart';

class RegistrationGuidePage extends StatefulWidget {
  final String groomName;
  final String brideName;

  const RegistrationGuidePage({
    super.key,
    required this.groomName,
    required this.brideName,
  });

  @override
  State<RegistrationGuidePage> createState() => _RegistrationGuidePageState();
}

class _RegistrationGuidePageState extends State<RegistrationGuidePage> {
  final Uri _sevanaUrl = Uri.parse('https://sevana.kerala.gov.in/');
  bool _isGeneratingPdf = false;

  Future<void> _launchUrl() async {
    if (!await launchUrl(_sevanaUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Sevana portal')),
        );
      }
    }
  }

  Future<void> _generateDraft() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await RegistrationDraftService.generateAndViewDraft(
        groomName: widget.groomName,
        brideName: widget.brideName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating draft: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Assistant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.brown.shade800,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF9F7F4),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Intro
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.deepOrange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      size: 48,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kerala Marriage Registration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Under the Kerala Registration of Marriages (Common) Rules, 2008, all marriages must be registered within 45 days.',
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Step-by-Step Guide
              Text(
                'Step-by-Step Process',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                '1',
                'Gather Documents',
                'Collect SSLC, Aadhaar, and passport-size photos for both the bride and groom.',
              ),
              _buildStepCard(
                '2',
                'Fill Application (Form 1)',
                'Use the Draft Generator below to prepare your Form 1 application details.',
              ),
              _buildStepCard(
                '3',
                'Online Submission',
                'Submit the application online via the Sevana portal or at your local Grama Panchayat / Municipality.',
              ),
              _buildStepCard(
                '4',
                'Witness Signatures',
                'Requires 2 witnesses with valid ID proofs to sign the register at the local body office.',
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _launchUrl,
                icon: const Icon(Icons.language),
                label: const Text('Visit Sevana Portal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _generateDraft,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isGeneratingPdf ? 'Generating...' : 'Generate Form 1 Draft',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Digital Vault Section
              Text(
                'Document Digital Vault',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Securely store copies of your legal documents here for quick access when filling out your forms.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              const DocumentVaultWidget(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(String stepNumber, String title, String description) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
