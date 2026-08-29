import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voice_model.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';

class ApiService {
  static String baseUrl = "https://mopidevi-voice-app.onrender.com"; // Online Render Cloud URL (works anywhere on 4G/5G/WiFi)

  static void setBaseUrl(String url) {
    baseUrl = url.replaceAll(RegExp(r'/$'), '');
  }

  // 1. Fetch Voice Profiles
  static Future<List<VoiceModel>> fetchVoices({String userId = 'user_default'}) async {
    final response = await http.get(Uri.parse('$baseUrl/api/voices?user_id=$userId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => VoiceModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load voices');
  }

  // 2. Fetch System Users
  static Future<List<SystemUser>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => SystemUser.fromJson(json)).toList();
    }
    throw Exception('Failed to load users');
  }

  // 3. Fetch User Assigned Voice
  static Future<Map<String, dynamic>> fetchUserAssignedVoice(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/$userId/assigned-voice'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load assigned voice');
  }

  // 4. Generate Announcement Job
  static Future<AnnouncementJob> generateAnnouncement({
    required String userId,
    required String voiceId,
    required String teluguScript,
    required String style,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/announcements/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'voice_id': voiceId,
        'telugu_script': teluguScript,
        'style': style,
      }),
    );
    if (response.statusCode == 200) {
      return AnnouncementJob.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Failed to generate announcement');
  }

  // 5. Poll Job Status
  static Future<AnnouncementJob> getJobStatus(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/announcements/jobs/$jobId'));
    if (response.statusCode == 200) {
      return AnnouncementJob.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Failed to get job status');
  }

  // 6. Pre-Upload Mobile Voice Quality Analysis
  static Future<Map<String, dynamic>> analyzeVoiceSample(String filePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/voices/analyze'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Voice analysis failed');
  }

  // 7. Upload Custom Voice Profile & Extract Neural Embedding
  static Future<Map<String, dynamic>> uploadVoiceProfile({
    required String voiceName,
    required String userId,
    required String filePath,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/voices/upload'));
    request.fields['voice_name'] = voiceName;
    request.fields['user_id'] = userId;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Voice upload failed');
  }

  // 8. Submit Word Training Sample
  static Future<Map<String, dynamic>> submitTrainingSample({
    required String reqId,
    required String voiceId,
    required String wordText,
    required String filePath,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/voices/train-sample'));
    request.fields['req_id'] = reqId;
    request.fields['voice_id'] = voiceId;
    request.fields['word_text'] = wordText;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Sample submission failed');
  }

  // 9. Fetch Pending Training Requests
  static Future<List<dynamic>> fetchPendingTrainingRequests(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/voices/training-requests/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load training requests');
  }

  // 10. Fetch Database Dataset Scripts
  static Future<List<dynamic>> fetchDatasetScripts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/training/dataset-scripts'));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Failed to load dataset scripts');
  }

  // 11. User Login Authentication (sid / Siddhu$1999)
  static Future<SystemUser> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return SystemUser.fromJson(data['user']);
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'Login failed');
    }
  }

  // 12. Admin: Create User with Auto-Generated IDs & Explicit Admin Password
  static Future<SystemUser> createUser({
    required String name,
    required String password,
    String mobileEmail = '',
    String role = 'operator',
    String status = 'Active',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'mobile_email': mobileEmail,
        'role': role,
        'status': status,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return SystemUser.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Failed to create user');
  }

  // 13. Admin: Delete User
  static Future<bool> deleteUser(String userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/users/$userId'));
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception('Failed to delete user');
  }

  // 14. User / Admin: Change Password (Verifies Current Password, Saves Plain Text)
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'Failed to change password');
    }
  }

  // 15. Admin: Set / Reset Password for any user without requiring old password
  static Future<Map<String, dynamic>> adminSetPassword({
    required String userId,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/users/set-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'Failed to update password');
    }
  }

  // 16. User Logout to record logout timestamp
  static Future<void> logout(String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}
  }
}

