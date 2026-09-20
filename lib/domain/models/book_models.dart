/// Codexa Domain Models
library;

enum SyncStatus {
  idle,
  checking,
  discovering,
  comparing,
  queued,
  downloading,
  verifying,
  updated,
  error,
}

enum DownloadStatus {
  notDownloaded,
  queued,
  downloading,
  paused,
  completed,
  failed,
  unavailable,
}

enum BookAvailability {
  full,
  partial,
  notDownloaded,
  cloudOnly,
}

// ════════════════════════════════════════════
// BOOK
// ════════════════════════════════════════════
class Book {
  final String id;
  final String driveFolderId;
  final String sourceName;
  final String? localTitle;
  final String? coverPath;
  final DateTime addedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final int totalDocuments;
  final int downloadedDocuments;
  final int totalBytes;
  final int downloadedBytes;

  const Book({
    required this.id,
    required this.driveFolderId,
    required this.sourceName,
    this.localTitle,
    this.coverPath,
    required this.addedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.idle,
    this.totalDocuments = 0,
    this.downloadedDocuments = 0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
  });

  String get title => localTitle ?? sourceName;

  double get downloadProgress =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0;

  bool get isFullyDownloaded => downloadedDocuments == totalDocuments && totalDocuments > 0;

  Book copyWith({
    String? localTitle,
    String? coverPath,
    DateTime? lastSyncedAt,
    SyncStatus? syncStatus,
    int? totalDocuments,
    int? downloadedDocuments,
    int? totalBytes,
    int? downloadedBytes,
  }) {
    return Book(
      id: id,
      driveFolderId: driveFolderId,
      sourceName: sourceName,
      localTitle: localTitle ?? this.localTitle,
      coverPath: coverPath ?? this.coverPath,
      addedAt: addedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      downloadedDocuments: downloadedDocuments ?? this.downloadedDocuments,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driveFolderId': driveFolderId,
      'sourceName': sourceName,
      'localTitle': localTitle,
      'coverPath': coverPath,
      'addedAt': addedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.index,
      'totalDocuments': totalDocuments,
      'downloadedDocuments': downloadedDocuments,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      driveFolderId: map['driveFolderId'] as String,
      sourceName: map['sourceName'] as String,
      localTitle: map['localTitle'] as String?,
      coverPath: map['coverPath'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.parse(map['lastSyncedAt'] as String)
          : null,
      syncStatus: SyncStatus.values[(map['syncStatus'] as int? ?? 0).clamp(0, SyncStatus.values.length - 1)],
      totalDocuments: map['totalDocuments'] as int? ?? 0,
      downloadedDocuments: map['downloadedDocuments'] as int? ?? 0,
      totalBytes: map['totalBytes'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
    );
  }
}

// ════════════════════════════════════════════
// BOOK SECTION
// ════════════════════════════════════════════
class BookSection {
  final String id;
  final String bookId;
  final String driveFolderId;
  final String? parentSectionId;
  final String sourceName;
  final String? localTitle;
  final int sortOrder;

  const BookSection({
    required this.id,
    required this.bookId,
    required this.driveFolderId,
    this.parentSectionId,
    required this.sourceName,
    this.localTitle,
    this.sortOrder = 0,
  });

  String get title => localTitle ?? sourceName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'driveFolderId': driveFolderId,
      'parentSectionId': parentSectionId,
      'sourceName': sourceName,
      'localTitle': localTitle,
      'sortOrder': sortOrder,
    };
  }

  factory BookSection.fromMap(Map<String, dynamic> map) {
    return BookSection(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      driveFolderId: map['driveFolderId'] as String,
      parentSectionId: map['parentSectionId'] as String?,
      sourceName: map['sourceName'] as String,
      localTitle: map['localTitle'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}

// ════════════════════════════════════════════
// BOOK DOCUMENT
// ════════════════════════════════════════════
class BookDocument {
  final String id;
  final String bookId;
  final String? sectionId;
  final String driveFileId;
  final String sourceName;
  final String? localPath;
  final String mimeType;
  final DateTime? cloudModifiedAt;
  final DateTime? localDownloadedAt;
  final int fileSize;
  final DownloadStatus downloadStatus;
  final BookAvailability availabilityStatus;

  const BookDocument({
    required this.id,
    required this.bookId,
    this.sectionId,
    required this.driveFileId,
    required this.sourceName,
    this.localPath,
    this.mimeType = 'application/pdf',
    this.cloudModifiedAt,
    this.localDownloadedAt,
    this.fileSize = 0,
    this.downloadStatus = DownloadStatus.notDownloaded,
    this.availabilityStatus = BookAvailability.cloudOnly,
  });

  String get title {
    final name = sourceName;
    if (name.toLowerCase().endsWith('.pdf') && name.length > 4) {
      return name.substring(0, name.length - 4);
    }
    return name;
  }
  bool get isDownloaded => downloadStatus == DownloadStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'sectionId': sectionId,
      'driveFileId': driveFileId,
      'sourceName': sourceName,
      'localPath': localPath,
      'mimeType': mimeType,
      'cloudModifiedAt': cloudModifiedAt?.toIso8601String(),
      'localDownloadedAt': localDownloadedAt?.toIso8601String(),
      'fileSize': fileSize,
      'downloadStatus': downloadStatus.index,
      'availabilityStatus': availabilityStatus.index,
    };
  }

  factory BookDocument.fromMap(Map<String, dynamic> map) {
    return BookDocument(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      sectionId: map['sectionId'] as String?,
      driveFileId: map['driveFileId'] as String,
      sourceName: map['sourceName'] as String,
      localPath: map['localPath'] as String?,
      mimeType: map['mimeType'] as String? ?? 'application/pdf',
      cloudModifiedAt: map['cloudModifiedAt'] != null
          ? DateTime.parse(map['cloudModifiedAt'] as String)
          : null,
      localDownloadedAt: map['localDownloadedAt'] != null
          ? DateTime.parse(map['localDownloadedAt'] as String)
          : null,
      fileSize: map['fileSize'] as int? ?? 0,
      downloadStatus: DownloadStatus.values[(map['downloadStatus'] as int? ?? 0).clamp(0, DownloadStatus.values.length - 1)],
      availabilityStatus:
          BookAvailability.values[(map['availabilityStatus'] as int? ?? 0).clamp(0, BookAvailability.values.length - 1)],
    );
  }
}

// ════════════════════════════════════════════
// READING PROGRESS
// ════════════════════════════════════════════
class ReadingProgress {
  final String id;
  final String documentId;
  final String bookId;
  final int currentPage;
  final int totalPages;
  final double progressPercent;
  final DateTime lastOpenedAt;

  const ReadingProgress({
    required this.id,
    required this.documentId,
    required this.bookId,
    required this.currentPage,
    this.totalPages = 0,
    this.progressPercent = 0,
    required this.lastOpenedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'bookId': bookId,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'progressPercent': progressPercent,
      'lastOpenedAt': lastOpenedAt.toIso8601String(),
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      bookId: map['bookId'] as String,
      currentPage: map['currentPage'] as int? ?? 0,
      totalPages: map['totalPages'] as int? ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toDouble() ?? 0,
      lastOpenedAt: map['lastOpenedAt'] != null
          ? DateTime.tryParse(map['lastOpenedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ════════════════════════════════════════════
// BOOKMARK
// ════════════════════════════════════════════
class Bookmark {
  final String id;
  final String documentId;
  final int page;
  final String? label;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.documentId,
    required this.page,
    this.label,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'page': page,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      page: map['page'] as int? ?? 0,
      label: map['label'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
