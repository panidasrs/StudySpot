import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

  
class CloudinaryService {
  static const String cloudName = 'dri8sokig';      
  static const String uploadPreset = 'studyspot_preset';   // unsigned preset

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// อัปโหลดรูปจาก File → คืน URL ของรูป
  static Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'studyspot';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String;   // https://res.cloudinary.com/...
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Cloudinary upload failed: $errorBody');
    }
  }

  /// แปลง URL เป็น thumbnail ขนาด 200×200
  static String thumbnail(String url, {int w = 200, int h = 200}) {
    if (!url.contains('cloudinary.com')) return url;
    return url.replaceFirst(
      '/upload/',
      '/upload/c_fill,w_$w,h_$h,q_auto,f_auto/',
    );
  }
}
