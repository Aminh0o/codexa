import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

class PdfMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final String? creator;
  final String? producer;
  final int pageCount;
  final DateTime? creationDate;
  final DateTime? modificationDate;

  const PdfMetadata({
    this.title,
    this.author,
    this.subject,
    this.creator,
    this.producer,
    this.pageCount = 0,
    this.creationDate,
    this.modificationDate,
  });
}

class PdfMetadataService {
  static Future<PdfMetadata> extractFromFile(String filePath) async {
    PdfDocument? document;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const PdfMetadata();
      }

      document = await PdfDocument.openFile(filePath);
      final pageCount = document.pages.length;

      // pdfrx doesn't expose metadata directly via a getter
      // Extract title from filename as fallback
      final title = extractTitleFromFilename(file.uri.pathSegments.last);

      return PdfMetadata(
        title: title,
        pageCount: pageCount,
      );
    } catch (e) {
      return const PdfMetadata();
    } finally {
      await document?.dispose();
    }
  }

  static Future<PdfMetadata> extractFromBytes(List<int> bytes) async {
    PdfDocument? document;
    try {
      final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      document = await PdfDocument.openData(uint8Bytes);
      final pageCount = document.pages.length;

      return PdfMetadata(pageCount: pageCount);
    } catch (e) {
      return const PdfMetadata();
    } finally {
      await document?.dispose();
    }
  }

  static String? extractTitleFromFilename(String filename) {
    // Remove extension
    var title = filename.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    // Replace underscores and hyphens with spaces
    title = title.replaceAll(RegExp(r'[_-]'), ' ');

    // Capitalize first letter of each word
    title = title.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    return title.isNotEmpty ? title : null;
  }

  static Future<Uint8List?> generateThumbnail(String filePath, {int width = 200, int height = 280}) async {
    PdfDocument? document;
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      document = await PdfDocument.openFile(filePath);
      if (document.pages.isEmpty) return null;

      final page = document.pages.first;
      final pageImage = await page.render(
        x: 0,
        y: 0,
        width: width,
        height: height,
        fullWidth: page.width,
        fullHeight: page.height,
      );

      if (pageImage == null) return null;

      // Convert raw RGBA pixels to PNG bytes
      final image = img.Image.fromBytes(
        width: pageImage.width,
        height: pageImage.height,
        bytes: pageImage.pixels.buffer,
        numChannels: 4,
      );
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      return null;
    } finally {
      await document?.dispose();
    }
  }

  static Future<Uint8List?> generateThumbnailFromBytes(List<int> bytes, {int width = 200, int height = 280}) async {
    PdfDocument? document;
    try {
      final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      document = await PdfDocument.openData(uint8Bytes);

      if (document.pages.isEmpty) return null;

      final page = document.pages.first;
      final pageImage = await page.render(
        x: 0,
        y: 0,
        width: width,
        height: height,
        fullWidth: page.width,
        fullHeight: page.height,
      );

      if (pageImage == null) return null;

      // Convert raw RGBA pixels to PNG bytes
      final image = img.Image.fromBytes(
        width: pageImage.width,
        height: pageImage.height,
        bytes: pageImage.pixels.buffer,
        numChannels: 4,
      );
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      return null;
    } finally {
      await document?.dispose();
    }
  }
}
