import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<String?> uploadFileToCloudinary(PlatformFile file) async {
  final cloudName = 'dui67nlwb';
  final uploadPreset = 'resume_preset';

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
  );

  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path!));

  final response = await request.send();

  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final data = json.decode(respStr);
    return data['secure_url']; // URL of uploaded file
  } else {
    print('Upload failed: ${response.statusCode}');
    return null;
  }
}
