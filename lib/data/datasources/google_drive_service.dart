import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';

class DriveFile {
  final String id;
  final String name;
  final String? mimeType;
  final String? parentId;
  final DateTime? modifiedTime;
  final int? size;
  final bool isFolder;

  DriveFile({
    required this.id,
    required this.name,
    this.mimeType,
    this.parentId,
    this.modifiedTime,
    this.size,
    this.isFolder = false,
  });

  factory DriveFile.fromJson(Map<String, dynamic> json) {
    return DriveFile(
      id: json['id'] as String,
      name: json['name'] as String,
      mimeType: json['mimeType'] as String?,
      parentId: (json['parents'] as List?)?.firstOrNull as String?,
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.parse(json['modifiedTime'] as String)
          : null,
      size: int.tryParse(json['size']?.toString() ?? ''),
      isFolder: json['mimeType'] == 'application/vnd.google-apps.folder',
    );
  }
}

class DriveListResult {
  final List<DriveFile> files;
  final String? nextPageToken;

  DriveListResult({required this.files, this.nextPageToken});
}

class GoogleDriveService {
  static const _baseUrl = 'https://www.googleapis.com/drive/v3';
  static const _filesEndpoint = '$_baseUrl/files';
  static const _pageSize = 50;
  static const _requestTimeout = Duration(seconds: 30);
  static const _downloadTimeout = Duration(minutes: 5);

  static Future<Map<String, String>> _getHeaders() async {
    final token = await GoogleAuthService.getValidAccessToken();
    if (token == null) throw DriveAuthException('Not authenticated. Please sign in again.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Refresh the access token and return new headers, or null if refresh failed.
  static Future<Map<String, String>?> _refreshAndGetHeaders() async {
    final newToken = await GoogleAuthService.tryRefreshToken();
    if (newToken == null) return null;
    return {
      'Authorization': 'Bearer $newToken',
      'Content-Type': 'application/json',
    };
  }

  /// Make an HTTP request with retry on 429 (rate limit) and 401 (token refresh)
  static Future<http.Response> _requestWithRetry(
    Future<http.Response> Function(Map<String, String> headers) request, {
    int maxRetries = 3,
  }) async {
    var headers = await _getHeaders();
    bool tokenRefreshed = false;
    bool wasRateLimited = false;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final response = await request(headers);
      if (response.statusCode == 429) {
        wasRateLimited = true;
        final retryAfter = response.headers['retry-after'];
        final delay = int.tryParse(retryAfter ?? '') ?? (30 * (attempt + 1));
        await Future.delayed(Duration(seconds: delay));
        continue;
      }
      // On 401, try refreshing token once and retry with fresh headers
      if (response.statusCode == 401 && !tokenRefreshed) {
        tokenRefreshed = true;
        final refreshedHeaders = await _refreshAndGetHeaders();
        if (refreshedHeaders != null) {
          headers = refreshedHeaders;
          continue;
        }
        // Refresh failed — session expired
        throw DriveAuthException('Session expired. Please sign in again.');
      }
      return response;
    }
    if (wasRateLimited) {
      throw DriveException('Rate limited. Please try again later.');
    }
    throw DriveException('Request failed after $maxRetries attempts.');
  }

  /// List files/folders in a directory
  static Future<DriveListResult> listFolder({
    String? folderId,
    String? pageToken,
    int pageSize = _pageSize,
  }) async {
    final queryParts = <String>[
      if (folderId != null) "'$folderId' in parents",
      'trashed = false',
    ];

    final params = <String, String>{
      'q': queryParts.join(' and '),
      'fields': 'nextPageToken, files(id, name, mimeType, parents, modifiedTime, size)',
      'pageSize': pageSize.toString(),
      'orderBy': 'name',
    };
    if (pageToken != null) params['pageToken'] = pageToken;

    final uri = Uri.parse(_filesEndpoint).replace(queryParameters: params);
    final response = await _requestWithRetry(
      (h) => http.get(uri, headers: h).timeout(_requestTimeout),
    );

    if (response.statusCode == 401) {
      throw DriveAuthException('Session expired. Please sign in again.');
    }
    if (response.statusCode == 403) {
      throw DrivePermissionException('Access denied. Please check Drive permissions.');
    }
    if (response.statusCode != 200) {
      throw DriveException('Drive API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final files = (data['files'] as List? ?? [])
        .map((f) => DriveFile.fromJson(f))
        .toList();

    return DriveListResult(
      files: files,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  /// List all folders (for folder picker)
  static Future<List<DriveFile>> listAllFolders({String? parentId}) async {
    final allFiles = <DriveFile>[];
    String? pageToken;

    do {
      final result = await listFolder(
        folderId: parentId,
        pageToken: pageToken,
      );
      allFiles.addAll(result.files.where((f) => f.isFolder));
      pageToken = result.nextPageToken;
    } while (pageToken != null);

    return allFiles;
  }

  /// Recursively discover all PDFs in a folder
  static Future<List<DriveFile>> discoverPDFs(String folderId) async {
    final pdfs = <DriveFile>[];
    await _discoverPDFsRecursive(folderId, pdfs);
    return pdfs;
  }

  /// Discover all PDF files recursively using iterative approach (prevents stack overflow)
  static Future<void> _discoverPDFsRecursive(
    String folderId,
    List<DriveFile> pdfs,
  ) async {
    // Iterative approach — no stack overflow on deeply nested folders
    final stack = [folderId];
    while (stack.isNotEmpty) {
      final currentFolderId = stack.removeLast();
      String? pageToken;
      do {
        final result = await listFolder(folderId: currentFolderId, pageToken: pageToken);
        for (final file in result.files) {
          if (file.isFolder) {
            stack.add(file.id);
          } else if (file.mimeType == 'application/pdf') {
            pdfs.add(file);
          }
        }
        pageToken = result.nextPageToken;
      } while (pageToken != null);
    }
  }

  /// Discover folder structure (sections/parts) — direct children only
  static Future<List<DriveFile>> discoverSubfolders(String folderId) async {
    final allFolders = <DriveFile>[];
    String? pageToken;
    do {
      final result = await listFolder(folderId: folderId, pageToken: pageToken);
      allFolders.addAll(result.files.where((f) => f.isFolder));
      pageToken = result.nextPageToken;
    } while (pageToken != null);
    return allFolders;
  }

  /// Recursively discover ALL subfolders at any depth (for nested part/chapter structures)
  /// Returns every folder under [rootFolderId], each with its own parentId intact.
  static Future<List<DriveFile>> discoverAllSubfoldersRecursive(String rootFolderId) async {
    final all = <DriveFile>[];
    final stack = [rootFolderId];
    while (stack.isNotEmpty) {
      final currentId = stack.removeLast();
      String? pageToken;
      do {
        final result = await listFolder(folderId: currentId, pageToken: pageToken);
        for (final f in result.files.where((f) => f.isFolder)) {
          all.add(f);
          stack.add(f.id);
        }
        pageToken = result.nextPageToken;
      } while (pageToken != null);
    }
    return all;
  }

  /// Get file metadata
  static Future<DriveFile?> getFile(String fileId) async {
    final uri = Uri.parse('$_filesEndpoint/$fileId')
        .replace(queryParameters: {
      'fields': 'id, name, mimeType, parents, modifiedTime, size',
    });
    final response = await _requestWithRetry(
      (h) => http.get(uri, headers: h).timeout(_requestTimeout),
    );
    if (response.statusCode == 401) {
      throw DriveAuthException('Session expired. Please sign in again.');
    }
    if (response.statusCode == 403) {
      throw DrivePermissionException('Access denied. Please check Drive permissions.');
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw DriveException('Failed to get file: ${response.statusCode}');
    }
    return DriveFile.fromJson(jsonDecode(response.body));
  }

  /// Download a file directly to disk (streaming, no memory OOM)
  static Future<void> downloadFileToDisk(String fileId, String destinationPath, {
    bool Function(double progress)? onProgress,
  }) async {
    var headers = await _getHeaders();
    final uri = Uri.parse('$_filesEndpoint/$fileId?alt=media');
    bool tokenRefreshed = false;

    for (int attempt = 0; attempt < 2; attempt++) {
      final client = http.Client();
      try {
        final request = http.Request('GET', uri);
        request.headers.addAll(headers);
        final response = await client.send(request).timeout(_downloadTimeout);

        if (response.statusCode == 401 && !tokenRefreshed) {
          tokenRefreshed = true;
          final refreshedHeaders = await _refreshAndGetHeaders();
          if (refreshedHeaders != null) {
            headers = refreshedHeaders;
            continue; // Retry with fresh headers
          }
        }
        if (response.statusCode == 401) {
          throw DriveAuthException('Session expired. Please sign in again.');
        }
        if (response.statusCode == 403) {
          throw DrivePermissionException('Access denied. Please check Drive permissions.');
        }
        if (response.statusCode != 200) {
          throw DriveException('Download failed: ${response.statusCode}');
        }

        final contentLength = response.contentLength ?? 0;
        final file = File(destinationPath);
        IOSink? sink;
        try {
          sink = file.openWrite();
          int bytesReceived = 0;

          await for (final chunk in response.stream) {
            sink!.add(chunk);
            bytesReceived += chunk.length;
            if (onProgress != null && contentLength > 0) {
              if (!onProgress(bytesReceived / contentLength)) {
                await sink.close();
                sink = null;
                throw DriveException('Download cancelled');
              }
            }
          }
          await sink!.close();
          sink = null;
          return; // Success
        } finally {
          if (sink != null) await sink.close();
        }
      } catch (e) {
        // Clean up partial file on failure
        final file = File(destinationPath);
        if (await file.exists()) {
          await file.delete();
        }
        rethrow;
      } finally {
        client.close();
      }
    }
  }

  /// Legacy: Download file to bytes (for small files only)
  static Future<List<int>> downloadFile(String fileId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_filesEndpoint/$fileId?alt=media');
    final response = await http.get(uri, headers: headers).timeout(_downloadTimeout);

    if (response.statusCode != 200) {
      throw DriveException('Download failed: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  /// Get download URL for a file
  static String getDownloadUrl(String fileId) {
    return '$_filesEndpoint/$fileId?alt=media';
  }

  /// Search for a folder by name in a parent
  static Future<DriveFile?> searchFolderByName(String name, {String? parentId}) async {
    // Escape backslashes and single quotes to prevent query injection
    final escapedName = name.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
    final queryParts = <String>[
      "name = '$escapedName'",
      "mimeType = 'application/vnd.google-apps.folder'",
      'trashed = false',
    ];
    if (parentId != null) {
      queryParts.add("'$parentId' in parents");
    }

    final params = <String, String>{
      'q': queryParts.join(' and '),
      'fields': 'files(id, name, mimeType, parents, modifiedTime, size)',
      'pageSize': '1',
    };

    final uri = Uri.parse(_filesEndpoint).replace(queryParameters: params);
    final response = await _requestWithRetry(
      (headers) => http.get(uri, headers: headers).timeout(_requestTimeout),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final files = data['files'] as List;
    if (files.isEmpty) return null;
    return DriveFile.fromJson(files.first);
  }

  /// Create a folder in Drive
  static Future<DriveFile> createFolder(String name, {String? parentId}) async {
    final body = <String, dynamic>{
      'name': name,
      'mimeType': 'application/vnd.google-apps.folder',
    };
    if (parentId != null) {
      body['parents'] = [parentId];
    }

    final params = <String, String>{
      'fields': 'id, name, mimeType, parents, modifiedTime, size',
    };

    final uri = Uri.parse(_filesEndpoint).replace(queryParameters: params);
    final response = await _requestWithRetry(
      (headers) => http.post(uri, headers: headers, body: jsonEncode(body)).timeout(_requestTimeout),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriveException('Failed to create folder: ${response.statusCode}');
    }

    return DriveFile.fromJson(jsonDecode(response.body));
  }

  /// Find or create the BOOKS folder in Drive root
  /// Returns the folder ID
  static Future<DriveFile> findOrCreateBooksFolder() async {
    const booksFolderName = 'BOOKS';

    // Search for existing BOOKS folder in root
    final existing = await searchFolderByName(booksFolderName);
    if (existing != null) return existing;

    // Create it if not found
    return await createFolder(booksFolderName);
  }

  /// Upload a file to a Drive folder
  static Future<DriveFile> uploadFile({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    required String parentId,
  }) async {
    var token = await GoogleAuthService.getValidAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final metadata = <String, dynamic>{
      'name': fileName,
      'parents': [parentId],
    };
    final metadataJson = jsonEncode(metadata);

    http.MultipartRequest buildRequest(String authToken) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
      );
      request.headers['Authorization'] = 'Bearer $authToken';
      request.fields['metadata'] = metadataJson;
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      return request;
    }

    // Multipart upload — do NOT include Content-Type in headers
    var request = buildRequest(token);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // Handle 429 rate limit with retry
    if (response.statusCode == 429) {
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
      await Future.delayed(Duration(seconds: retryAfter));
      token = await GoogleAuthService.getValidAccessToken() ?? token;
      request = buildRequest(token);
      streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    }

    // On 401, try refreshing token once and retry with NEW request
    if (response.statusCode == 401) {
      final refreshedHeaders = await _refreshAndGetHeaders();
      if (refreshedHeaders != null) {
        token = refreshedHeaders['Authorization']?.replaceFirst('Bearer ', '');
        if (token != null) {
          // MUST rebuild — MultipartRequest is single-use (body stream consumed)
          request = buildRequest(token);
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }
      }
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriveException('Upload failed: ${response.statusCode}');
    }

    return DriveFile.fromJson(jsonDecode(response.body));
  }

  /// Search for a file by name in a parent
  static Future<DriveFile?> searchFileByName(String name, {String? parentId}) async {
    final escapedName = name.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
    final queryParts = <String>[
      "name = '$escapedName'",
      'trashed = false',
    ];
    if (parentId != null) {
      queryParts.add("'$parentId' in parents");
    }

    final params = <String, String>{
      'q': queryParts.join(' and '),
      'fields': 'files(id, name, mimeType, parents, modifiedTime, size)',
      'pageSize': '1',
    };

    final uri = Uri.parse(_filesEndpoint).replace(queryParameters: params);
    final response = await _requestWithRetry(
      (headers) => http.get(uri, headers: headers).timeout(_requestTimeout),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final files = data['files'] as List;
    if (files.isEmpty) return null;
    return DriveFile.fromJson(files.first);
  }

  /// List ALL files matching an exact name within a parent (ordered newest
  /// first). Used to detect and deterministically resolve duplicate sync
  /// metadata instead of blindly accepting an arbitrary match.
  static Future<List<DriveFile>> listFilesByName(String name, {String? parentId}) async {
    final escapedName = name.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
    final queryParts = <String>[
      "name = '$escapedName'",
      'trashed = false',
    ];
    if (parentId != null) {
      queryParts.add("'$parentId' in parents");
    }

    final params = <String, String>{
      'q': queryParts.join(' and '),
      'fields': 'files(id, name, mimeType, parents, modifiedTime, size)',
      'pageSize': '100',
      'orderBy': 'modifiedTime desc',
    };

    final uri = Uri.parse(_filesEndpoint).replace(queryParameters: params);
    final response = await _requestWithRetry(
      (headers) => http.get(uri, headers: headers).timeout(_requestTimeout),
    );

    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body);
    final files = data['files'] as List? ?? [];
    return files.map((f) => DriveFile.fromJson(f as Map<String, dynamic>)).toList();
  }

  /// Update an existing file's content in place (media PATCH), preserving its
  /// Drive file ID so only one generation of a given file ever exists.
  static Future<DriveFile> updateFileBytes(
    String fileId,
    List<int> bytes, {
    String mimeType = 'application/json',
  }) async {
    final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$fileId')
        .replace(queryParameters: {'uploadType': 'media', 'fields': 'id, name, modifiedTime'});

    Future<http.Response> send(String authToken) async {
      final client = http.Client();
      try {
        final request = http.Request('PATCH', uri);
        request.headers['Authorization'] = 'Bearer $authToken';
        request.headers['Content-Type'] = mimeType;
        request.bodyBytes = bytes;
        final streamed = await client.send(request).timeout(_requestTimeout);
        return await http.Response.fromStream(streamed);
      } finally {
        client.close();
      }
    }

    var token = await GoogleAuthService.getValidAccessToken();
    if (token == null) throw DriveAuthException('Not authenticated. Please sign in again.');
    var response = await send(token);

    // On 401, refresh once and retry.
    if (response.statusCode == 401) {
      final refreshed = await _refreshAndGetHeaders();
      final newToken = refreshed?['Authorization']?.replaceFirst('Bearer ', '');
      if (newToken != null) {
        token = newToken;
        response = await send(token);
      } else {
        throw DriveAuthException('Session expired. Please sign in again.');
      }
    }
    // On 429, back off once and retry.
    if (response.statusCode == 429) {
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
      await Future.delayed(Duration(seconds: retryAfter));
      token = await GoogleAuthService.getValidAccessToken() ?? token;
      response = await send(token);
    }

    if (response.statusCode != 200) {
      throw DriveException('Update failed: ${response.statusCode}');
    }
    return DriveFile.fromJson(jsonDecode(response.body));
  }

  /// Delete a file
  static Future<void> deleteFile(String fileId) async {
    final uri = Uri.parse('$_filesEndpoint/$fileId');
    await _requestWithRetry(
      (headers) => http.delete(uri, headers: headers).timeout(_requestTimeout),
    );
  }

  /// Check if Drive is accessible
  static Future<bool> checkAccess() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/about?fields=user'),
        headers: headers,
      ).timeout(_requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class DriveException implements Exception {
  final String message;
  DriveException(this.message);
  @override
  String toString() => message;
}

class DriveAuthException extends DriveException {
  DriveAuthException(super.message);
}

class DrivePermissionException extends DriveException {
  DrivePermissionException(super.message);
}
