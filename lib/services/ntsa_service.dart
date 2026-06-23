import 'dart:convert';
import 'package:http/http.dart' as http;

class NTSAService {
  static const String _baseUrl = 'https://api.ntsa.go.ke/v1';

  bool useMockApi = true;

  Future<Map<String, dynamic>> verifyDriversLicense(String licenseNumber) async {
    if (useMockApi) {
      await Future.delayed(const Duration(seconds: 2));
      final isValid = RegExp(r'^[A-Z0-9]{3}-\d{4}-[A-Z0-9]{3}$').hasMatch(
        licenseNumber.toUpperCase(),
      );
      return {
        'verified': isValid,
        'message': isValid
            ? 'License verified successfully'
            : 'Invalid license number format (use XXX-XXXX-XXX)',
      };
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/driving-licenses/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'licenseNumber': licenseNumber}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyVehicleRegistration(String regNumber) async {
    if (useMockApi) {
      await Future.delayed(const Duration(seconds: 2));
      final isValid = RegExp(r'^[A-Z]{3}\s?\d{3}[A-Z]$').hasMatch(
        regNumber.toUpperCase(),
      );
      return {
        'verified': isValid,
        'message': isValid
            ? 'Vehicle registration verified'
            : 'Invalid plate number format (e.g. KCA 123T)',
        'vehicleDetails': isValid
            ? {
                'make': 'Toyota',
                'model': 'Axio',
                'year': 2020,
                'color': 'White',
              }
            : null,
      };
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/vehicles/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'registrationNumber': regNumber}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyPSVBadge(String badgeNumber) async {
    if (useMockApi) {
      await Future.delayed(const Duration(seconds: 2));
      final isValid = badgeNumber.length >= 6;
      return {
        'verified': isValid,
        'message': isValid
            ? 'PSV badge verified'
            : 'Invalid PSV badge number',
      };
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/psv-badges/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'badgeNumber': badgeNumber}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyInsurance(String policyNumber) async {
    if (useMockApi) {
      await Future.delayed(const Duration(seconds: 2));
      return {
        'verified': policyNumber.isNotEmpty,
        'message': policyNumber.isNotEmpty
            ? 'Insurance verified'
            : 'Invalid policy number',
      };
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/insurance/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'policyNumber': policyNumber}),
    );
    return jsonDecode(response.body);
  }
}
