import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart';

class CloudinaryService {
  final String cloudName = "dui67nlwb";
  final String uploadPreset = "c_cube_domain_image";

  Future<String?> uploadImage(File imageFile) async {
    final mimeType = lookupMimeType(imageFile.path);

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath(
              'file',
              imageFile.path,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
            ),
          );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      return jsonResponse['secure_url'];
    } else {
      Fluttertoast.showToast(
        msg: "upload failed image with code: ${response.statusCode}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return null;
    }
  }
}
