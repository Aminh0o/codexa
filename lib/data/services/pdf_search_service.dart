import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfSearchResult {
  final int pageNumber;
  final String text;
  final int startIndex;
  final int endIndex;

  const PdfSearchResult({
    required this.pageNumber,
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });
}

class _PageTextData {
  final int pageNumber;
  final String text;
  const _PageTextData(this.pageNumber, this.text);
}

List<PdfSearchResult> _searchPdfIsolate(
  List<_PageTextData> pages,
  String query,
  int maxResults,
) {
  final results = <PdfSearchResult>[];
  final queryLower = query.toLowerCase();

  for (final page in pages) {
    if (results.length >= maxResults) break;

    final textStr = page.text;
    final textLower = textStr.toLowerCase();

    int startIndex = 0;
    while (startIndex < textLower.length) {
      final index = textLower.indexOf(queryLower, startIndex);
      if (index == -1) break;

      final matchedText = textStr.substring(
        math.max(0, index - 20),
        math.min(textStr.length, index + query.length + 30),
      );

      results.add(PdfSearchResult(
        pageNumber: page.pageNumber,
        text: matchedText,
        startIndex: index,
        endIndex: index + query.length,
      ));

      if (results.length >= maxResults) break;
      startIndex = index + 1;
    }
  }

  return results;
}

class PdfSearchService {
  static Future<List<PdfSearchResult>> searchInPdf(
    String filePath,
    String query, {
    int maxResults = 100,
  }) async {
    if (query.isEmpty) return [];
    PdfDocument? document;
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];

      document = await PdfDocument.openFile(filePath);
      final pageTexts = <_PageTextData>[];

      for (final page in document.pages) {
        final text = await page.loadText();
        if (text != null) {
          pageTexts.add(_PageTextData(page.pageNumber, text.fullText));
        }
      }

      return await Isolate.run(
        () => _searchPdfIsolate(pageTexts, query, maxResults),
      );
    } catch (e) {
      debugPrint('[PdfSearch] Search failed: $e');
      return [];
    } finally {
      await document?.dispose();
    }
  }

  static Future<List<PdfSearchResult>> searchInPdfBytes(
    List<int> bytes,
    String query, {
    int maxResults = 100,
  }) async {
    PdfDocument? document;
    if (query.isEmpty) return [];

    try {
      final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      document = await PdfDocument.openData(uint8Bytes);
      final pageTexts = <_PageTextData>[];

      for (final page in document.pages) {
        final text = await page.loadText();
        if (text != null) {
          pageTexts.add(_PageTextData(page.pageNumber, text.fullText));
        }
      }

      return await Isolate.run(
        () => _searchPdfIsolate(pageTexts, query, maxResults),
      );
    } catch (e) {
      debugPrint('[PdfSearch] Search failed: $e');
      return [];
    } finally {
      await document?.dispose();
    }
  }

  static Future<int> getPageCount(String filePath) async {
    PdfDocument? document;
    try {
      final file = File(filePath);
      if (!await file.exists()) return 0;

      document = await PdfDocument.openFile(filePath);
      return document.pages.length;
    } catch (e) {
      debugPrint('[PdfSearch] getPageCount failed: $e');
      return 0;
    } finally {
      await document?.dispose();
    }
  }
}
