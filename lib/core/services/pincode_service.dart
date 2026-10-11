import 'dart:convert';
import 'package:http/http.dart' as http;

class PincodeLocation {
  final String postOffice;
  final String taluk;
  final String district;
  final String state;
  final String panchayath;

  PincodeLocation({
    required this.postOffice,
    required this.taluk,
    required this.district,
    required this.state,
    this.panchayath = '',
  });
}

class PincodeService {
  static Future<List<PincodeLocation>> fetchLocation(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          if (result['Status'] == 'Success' && result['PostOffice'] != null) {
            final postOffices = result['PostOffice'] as List;
            return postOffices
                .map(
                  (po) {
                    final block = po['Block']?.toString() ?? '';
                    final region = po['Region']?.toString() ?? '';
                    final division = po['Division']?.toString() ?? '';
                    final talukVal = (block.isNotEmpty && block != 'NA')
                        ? block
                        : (division.isNotEmpty && division != 'NA' ? division : region);
                    final panchVal = (block.isNotEmpty && block != 'NA') ? block : talukVal;
                    return PincodeLocation(
                      postOffice: po['Name']?.toString() ?? '',
                      taluk: talukVal,
                      district: po['District']?.toString() ?? '',
                      state: po['State']?.toString() ?? 'Kerala',
                      panchayath: panchVal,
                    );
                  },
                )
                .toList();
          }
        }
      }
    } catch (e) {
      // Ignored for now
    }
    return [];
  }
}
