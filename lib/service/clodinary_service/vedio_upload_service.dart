import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';

final videoCompress = VideoCompress;

/// Maximum allowed video size in bytes (50 MB)
const int maxVideoSize = 50 * 1024 * 1024;

/// Compress video before upload
Future<File?> compressVideo(File file) async {
  // Check original file size
  if (await file.length() > maxVideoSize) {
    print("❌ Video is larger than 50 MB");
    return null;
  }

  final info = await videoCompress.compressVideo(
    file.path,
    quality: VideoQuality.MediumQuality,
    deleteOrigin: false,
  );

  // Check compressed file size
  if (info != null &&
      info.file != null &&
      await info.file!.length() > maxVideoSize) {
    print("❌ Compressed video is still larger than 50 MB");
    return null;
  }

  return info?.file;
}

/// Upload video to Cloudinary
Future<String?> uploadVideoToCloudinary(File videoFile) async {
  final String cloudName = "dui67nlwb"; // Replace with your cloud name
  final String uploadPreset = "project_vedio"; // Your preset name

  // Check file size again before upload
  if (await videoFile.length() > maxVideoSize) {
    print("❌ Video exceeds 50 MB, cannot upload");
    return null;
  }

  try {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
    );

    final request =
        http.MultipartRequest("POST", url)
          ..fields["upload_preset"] = uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath("file", videoFile.path),
          );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      return data["secure_url"]; // Cloudinary URL
    } else {
      print("❌ Cloudinary upload error: $resBody");
      return null;
    }
  } catch (e) {
    print("❌ Exception while uploading video: $e");
    return null;
  }
}
