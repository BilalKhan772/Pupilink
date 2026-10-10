
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'file_upload_result.dart';

class FirebaseStorageClient {
  FirebaseStorageClient({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<FileUploadResult> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    SettableMetadata? metadata,
  }) async {
    final normalizedPath = _validatePath(path);

    if (bytes.isEmpty) {
      throw ArgumentError('Upload file is empty.');
    }

    final reference = _storage.ref().child(normalizedPath);

    final uploadMetadata = metadata ??
        SettableMetadata(
          contentType: contentType,
        );

    final snapshot = await reference.putData(bytes, uploadMetadata);
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return FileUploadResult(
      fullPath: snapshot.ref.fullPath,
      downloadUrl: downloadUrl,
      name: snapshot.ref.name,
      size: snapshot.totalBytes,
      contentType: snapshot.metadata?.contentType ?? contentType,
    );
  }

  Future<String> getDownloadUrl(String path) async {
    return _storage.ref().child(_validatePath(path)).getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref().child(_validatePath(path)).delete();
  }

  Future<FullMetadata> getMetadata(String path) async {
    return _storage.ref().child(_validatePath(path)).getMetadata();
  }

  String _validatePath(String path) {
    final normalized = path.trim();

    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        normalized.split('/').any((part) => part == '..')) {
      throw ArgumentError.value(path, 'path', 'Invalid storage path.');
    }

    return normalized;
  }
}
