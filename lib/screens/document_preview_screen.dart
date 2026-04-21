import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class DocumentPreviewScreen extends StatefulWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.fileUrl,
    this.localPath,
  });

  final String fileUrl;
  final String? localPath;

  static bool isPdf(String value) {
    return _extension(value) == 'pdf';
  }

  static bool isDocOrExcel(String value) {
    const docExcelExtensions = {'doc', 'docx', 'xls', 'xlsx'};
    return docExcelExtensions.contains(_extension(value));
  }

  static Future<void> openDocument(
    BuildContext context, {
    required String fileUrl,
    String? localPath,
  }) async {
    if (!context.mounted) return;

    final sourceForType = (localPath ?? '').trim().isNotEmpty
        ? localPath!.trim()
        : fileUrl.trim();

    if (sourceForType.isEmpty) {
      _showSnackBar(context, 'File not found.');
      return;
    }

    if (isPdf(sourceForType)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DocumentPreviewScreen(fileUrl: fileUrl, localPath: localPath),
        ),
      );
      return;
    }

    if (isDocOrExcel(sourceForType)) {
      await _openDocOrExcelExternally(
        context,
        fileUrl: fileUrl,
        localPath: localPath,
      );
      return;
    }

    _showSnackBar(context, 'Unsupported file format.');
  }

  static Future<void> _openDocOrExcelExternally(
    BuildContext context, {
    required String fileUrl,
    String? localPath,
  }) async {
    if (!context.mounted) return;

    final normalizedLocalPath = (localPath ?? '').trim();
    String pathToOpen = normalizedLocalPath;

    _showLoading(context, message: 'Opening document...');
    try {
      if (pathToOpen.isEmpty) {
        final normalizedUrl = fileUrl.trim();
        if (normalizedUrl.isEmpty) {
          throw Exception('File not found.');
        }

        final uri = Uri.tryParse(normalizedUrl);
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          throw Exception('Invalid document URL.');
        }

        pathToOpen = await _downloadToTemp(normalizedUrl);
      }

      final result = await OpenFile.open(pathToOpen);
      if (result.type != ResultType.done) {
        throw Exception(
          result.message.isEmpty
              ? 'No app found to open file.'
              : result.message,
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(
          context,
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    }
  }

  static Future<String> _downloadToTemp(String url) async {
    final uri = Uri.parse(url);
    final ext = _extension(url);
    final guessedName = _guessFileName(uri, ext);
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}${Platform.pathSeparator}$guessedName';

    await Dio().download(url, targetPath);
    final exists = await File(targetPath).exists();
    if (!exists) {
      throw Exception('Downloaded file not found.');
    }
    return targetPath;
  }

  static String _guessFileName(Uri uri, String ext) {
    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (segment.trim().isNotEmpty) {
      return segment;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return ext.isEmpty ? 'document_$timestamp' : 'document_$timestamp.$ext';
  }

  static String _extension(String value) {
    final input = value.trim();
    if (input.isEmpty) return '';

    final uri = Uri.tryParse(input);
    final source = uri != null && uri.path.isNotEmpty ? uri.path : input;
    final cleaned = source
        .replaceAll('\\', '/')
        .split('?')
        .first
        .split('#')
        .first;
    final lastSlash = cleaned.lastIndexOf('/');
    final fileName = lastSlash >= 0
        ? cleaned.substring(lastSlash + 1)
        : cleaned;
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dot + 1).toLowerCase();
  }

  static void _showLoading(BuildContext context, {required String message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    AppSnackbar.show('Notice', message);
  }

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  late final String _fileUrl;
  late final String? _localPath;

  @override
  void initState() {
    super.initState();
    _fileUrl = widget.fileUrl.trim();
    final normalizedLocal = (widget.localPath ?? '').trim();
    _localPath = normalizedLocal.isEmpty ? null : normalizedLocal;
  }

  @override
  Widget build(BuildContext context) {
    final sourceForType = _localPath ?? _fileUrl;
    if (!DocumentPreviewScreen.isPdf(sourceForType)) {
      return Scaffold(
        appBar: const CommonScreenAppBar(title: 'Document Preview'),
        body: const Center(child: Text('Unsupported file format.')),
      );
    }

    return Scaffold(
      appBar: const CommonScreenAppBar(title: 'PDF Preview'),
      body: _buildPdfViewer(),
    );
  }

  Widget _buildPdfViewer() {
    final localPath = _localPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return SfPdfViewer.file(file);
      }
    }

    if (_fileUrl.isEmpty) {
      return const Center(child: Text('File not found.'));
    }
    return SfPdfViewer.network(_fileUrl);
  }
}
