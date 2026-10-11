import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentVaultWidget extends StatefulWidget {
  const DocumentVaultWidget({super.key});

  @override
  State<DocumentVaultWidget> createState() => _DocumentVaultWidgetState();
}

class _DocumentVaultWidgetState extends State<DocumentVaultWidget> {
  final Map<String, String?> _uploadedFiles = {
    "Groom's SSLC / Age Proof": null,
    "Bride's SSLC / Age Proof": null,
    "Groom's Aadhaar": null,
    "Bride's Aadhaar": null,
  };

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png'],
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        setState(() {
          _uploadedFiles[documentType] = result.files.single.name;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully uploaded ${result.files.single.name}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  void _removeFile(String documentType) {
    setState(() {
      _uploadedFiles[documentType] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.brown.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: _uploadedFiles.entries.map((entry) {
            final isUploaded = entry.value != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Icon(
                    isUploaded ? Icons.check_circle : Icons.upload_file,
                    color: isUploaded ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isUploaded)
                          Text(
                            entry.value!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isUploaded)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeFile(entry.key),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _pickFile(entry.key),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade100,
                        foregroundColor: Colors.brown.shade900,
                        elevation: 0,
                      ),
                      child: const Text('Upload'),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
