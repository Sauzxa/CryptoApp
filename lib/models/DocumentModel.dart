class FolderModel {
  final String id;
  final String name;
  final String? description;
  final List<String> allowedRoles;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.name,
    this.description,
    required this.allowedRoles,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      allowedRoles: List<String>.from(json['allowedRoles'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'allowedRoles': allowedRoles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class DocumentModel {
  final String id;
  final String folderId;
  final String name;
  final String mimeType;
  final String filePath;
  final int fileSize;
  final String createdBy;
  final List<String> allowedRoles;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.folderId,
    required this.name,
    required this.mimeType,
    required this.filePath,
    required this.fileSize,
    required this.createdBy,
    required this.allowedRoles,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['_id'] ?? json['id'] ?? '',
      folderId: json['folderId'] ?? '',
      name: json['name'] ?? '',
      mimeType: json['mimeType'] ?? 'application/octet-stream',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      createdBy: json['createdBy'] ?? '',
      allowedRoles: List<String>.from(json['allowedRoles'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'folderId': folderId,
      'name': name,
      'mimeType': mimeType,
      'filePath': filePath,
      'fileSize': fileSize,
      'createdBy': createdBy,
      'allowedRoles': allowedRoles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isPDF => mimeType.contains('pdf') || fileExtension == 'pdf';
  bool get isImage => mimeType.startsWith('image/') || ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(fileExtension);
  bool get isDocument => ['doc', 'docx', 'txt', 'odt'].contains(fileExtension);
  bool get isSpreadsheet => ['xls', 'xlsx', 'csv', 'ods'].contains(fileExtension);
  bool get isPresentation => ['ppt', 'pptx', 'odp'].contains(fileExtension);
}
