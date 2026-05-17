import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// UploadUtils - Platform-aware file upload utility
/// Use this for mobile/desktop platforms. For web, use SupabaseUploadHelper.
class UploadUtils {
	/// Upload a file to Supabase Storage and return the public URL
	static Future<String> uploadFile({
		required File file,
		required String bucket,
		required String folder,
	}) async {
		final client = Supabase.instance.client;
		final ext = file.path.split('.').last;
		final fileName = '${DateTime.now().millisecondsSinceEpoch}.${ext}';
		final path = '$folder/$fileName';

		// Upload the file - returns the path on success
		await client.storage.from(bucket).upload(path, file);
		
		// Get the public URL
		final publicUrl = client.storage.from(bucket).getPublicUrl(path);
		return publicUrl;
	}

	/// Upload multiple files to Supabase Storage
	static Future<List<String>> uploadFiles({
		required List<File> files,
		required String bucket,
		required String folder,
	}) async {
		final urls = <String>[];
		for (final file in files) {
			final url = await uploadFile(
				file: file,
				bucket: bucket,
				folder: folder,
			);
			urls.add(url);
		}
		return urls;
	}
}
