
class FileUploadResult {
  const FileUploadResult({
    required this.fullPath,
    required this.downloadUrl,
    required this.name,
    required this.size,
    this.contentType,
  });

  final String fullPath;
  final String downloadUrl;
  final String name;
  final int size;
  final String? contentType;

  Map<String, dynamic> toMap() {
    return {
      'fullPath': fullPath,
      'downloadUrl': downloadUrl,
      'name': name,
      'size': size,
      'contentType': contentType,
    };
  }

  factory FileUploadResult.fromMap(Map<String, dynamic> map) {
    return FileUploadResult(
      fullPath: map['fullPath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      name: map['name'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      contentType: map['contentType'] as String?,
    );
  }
}
