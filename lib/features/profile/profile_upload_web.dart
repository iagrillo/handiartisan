import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../utils/supabase.dart';

Future<void> platformHandleProfileUpload({
  required BuildContext context,
  required Function(String publicUrl) onSuccess,
  required Function(String error) onError,
  required Function(bool uploading) setUploading,
}) async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();
  uploadInput.onChange.listen((e) async {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      setUploading(true);
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) async {
        final result = reader.result;
        Uint8List bytes;
        if (result is ByteBuffer) {
          bytes = Uint8List.view(result);
        } else if (result is Uint8List) {
          bytes = result;
        } else {
          setUploading(false);
          onError('FileReader did not return ByteBuffer or Uint8List.');
          return;
        }
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final storage = SupabaseUtils.client.storage.from('artisan-media');
        try {
          await storage.uploadBinary(fileName, bytes);
          final publicUrl = storage.getPublicUrl(fileName);
          setUploading(false);
          onSuccess(publicUrl);
        } catch (e) {
          setUploading(false);
          onError('Profile image upload failed: ' + e.toString());
        }
      });
    } else {
      onError('No file selected for upload.');
    }
  });
}
