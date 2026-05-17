import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/supabase.dart';

Future<void> platformHandleProfileUpload({
  required BuildContext context,
  required Function(String publicUrl) onSuccess,
  required Function(String error) onError,
  required Function(bool uploading) setUploading,
}) async {
  final ImagePicker picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setUploading(true);
    try {
      Uint8List bytes = await pickedFile.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final storage = SupabaseUtils.client.storage.from('artisan-media');
      await storage.uploadBinary(fileName, bytes);
      final publicUrl = storage.getPublicUrl(fileName);
      setUploading(false);
      onSuccess(publicUrl);
    } catch (e) {
      setUploading(false);
      onError('Profile image upload failed: ' + e.toString());
    }
  } else {
    onError('No file selected for upload.');
  }
}
