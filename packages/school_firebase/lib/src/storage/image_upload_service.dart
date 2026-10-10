
import 'dart:typed_data';

import 'file_upload_result.dart';
import 'firebase_storage_client.dart';

class ImageUploadService {
  ImageUploadService({FirebaseStorageClient? storageClient})
      : _storageClient = storageClient ?? FirebaseStorageClient();

  final FirebaseStorageClient _storageClient;

  Future<FileUploadResult> uploadImage({
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (!contentType.startsWith('image/')) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'Only image content types are allowed.',
      );
    }

    return _storageClient.uploadBytes(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<void> deleteImage(String path) {
    return _storageClient.deleteFile(path);
  }

  Future<String> getImageUrl(String path) {
    return _storageClient.getDownloadUrl(path);
  }
}
