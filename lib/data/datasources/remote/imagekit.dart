import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageKitDataSource {
  final String _privateKey = dotenv.get('IMAGEKIT_PRIVATE_KEY', fallback: '');
  final String _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

  Future<String?> uploadImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        developer.log('ImageKit: Local file not found at $localPath');
        return null;
      }

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      final String basicAuth = base64Encode(utf8.encode('$_privateKey:'));
      request.headers['Authorization'] = 'Basic $basicAuth';

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

      request.fields['fileName'] = fileName;
      request.fields['folder'] = '/mood_tracker';
      request.fields['useUniqueFileName'] = 'true';

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        final String remoteUrl = data['url'];
        developer.log('ImageKit: Upload success -> $remoteUrl');
        return remoteUrl;
      } else {
        final errorResponse = await response.stream.bytesToString();
        developer.log(
          'ImageKit: Upload failed (${response.statusCode}): $errorResponse',
        );
        return null;
      }
    } catch (e) {
      developer.log('ImageKit: Critical upload error: $e');
      return null;
    }
  }
}
