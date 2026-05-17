import 'package:flutter/material.dart';

Future<void> platformHandleProfileUpload({
  required BuildContext context,
  required Function(String publicUrl) onSuccess,
  required Function(String error) onError,
  required Function(bool uploading) setUploading,
}) async {
  onError('Profile upload not supported on this platform.');
}
