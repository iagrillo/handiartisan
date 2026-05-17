import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseUploadHelper {
  static final SupabaseClient client = Supabase.instance.client;
  static const String bucket = 'artisan-media';

  static Future<String?> uploadImage(
    dynamic fileOrBytes, {
    String? folder,
    String? fileName,
  }) async {
    try {
      final Uint8List bytes = await _toBytes(fileOrBytes);
      if (bytes.isEmpty) return null;

      final ext = _resolveExtension(fileOrBytes, fileName);
      final generatedName = fileName ?? '${const Uuid().v4()}.$ext';
      final filePath = (folder != null && folder.trim().isNotEmpty)
          ? '${folder.trim()}/$generatedName'
          : generatedName;

      await client.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeFromExt(ext),
            ),
          );

      return client.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow; // IMPORTANT: expose real error to caller
    }
  }

  static Future<bool> deleteImage(String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  static Future<Uint8List> _toBytes(dynamic input) async {
    if (input is Uint8List) return input;
    if (input is List<int>) return Uint8List.fromList(input);
    if (input is File) return await input.readAsBytes();
    if (input is String) {
      final f = File(input);
      if (!await f.exists()) throw Exception('File path does not exist: $input');
      return await f.readAsBytes();
    }
    throw Exception('Unsupported upload input type: ${input.runtimeType}');
  }

  static String _resolveExtension(dynamic fileOrBytes, String? fileName) {
    if (fileName != null && fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    if (fileOrBytes is File && fileOrBytes.path.contains('.')) {
      return fileOrBytes.path.split('.').last.toLowerCase();
    }
    return 'jpg';
  }

  static String _contentTypeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}