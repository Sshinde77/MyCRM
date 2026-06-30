import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../core/constants/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.endpoint,
  });

  final String title;
  final String endpoint;

  Future<String> _loadDocument() async {
    final response = await ApiService.instance.get(endpoint);
    return _extractContent(response.data);
  }

  String _extractContent(dynamic data) {
    if (data == null) return '';

    if (data is Map<String, dynamic>) {
      return _extractFromMap(data);
    }

    if (data is Map) {
      return _extractFromMap(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return '';

      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return _extractFromMap(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        if (decoded is String) {
          return decoded.trim();
        }
      } catch (_) {
        final contentMatch = RegExp(
          r'content\s*:\s*(.*)$',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(trimmed);
        if (contentMatch != null) {
          return _stripWrappingBraces(contentMatch.group(1)?.trim() ?? '');
        }
        return trimmed;
      }
    }

    return data.toString().trim();
  }

  String _extractFromMap(Map<String, dynamic> data) {
    for (final key in const ['content', 'body', 'html', 'markdown', 'text']) {
      final value = data[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) return _stripWrappingBraces(normalized);
    }
    return _stripWrappingBraces(data.toString().trim());
  }

  String _stripWrappingBraces(String value) {
    var result = value.trim();
    if (result.startsWith('{') && result.endsWith('}')) {
      result = result.substring(1, result.length - 1).trim();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: CommonScreenAppBar(title: title),
      body: FutureBuilder<String>(
        future: _loadDocument(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load document.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    color: const Color(0xFF334155),
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          final content = snapshot.data?.trim() ?? '';
          final html = content.isEmpty ? '<p>No content available.</p>' : content;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Html(
              data: html,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  color: const Color(0xFF334155),
                  fontSize: FontSize(15),
                  lineHeight: const LineHeight(1.55),
                  fontFamily: AppTextStyles.body().fontFamily,
                ),
                'h1': Style(
                  margin: Margins.only(bottom: 12),
                  color: const Color(0xFF0F172A),
                  fontSize: FontSize(26),
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.title().fontFamily,
                ),
                'h2': Style(
                  margin: Margins.only(top: 20, bottom: 10),
                  color: const Color(0xFF0F172A),
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.title().fontFamily,
                ),
                'h3': Style(
                  margin: Margins.only(top: 18, bottom: 8),
                  color: const Color(0xFF0F172A),
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.subtitle().fontFamily,
                ),
                'p': Style(margin: Margins.only(bottom: 12)),
                'strong': Style(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                'ul': Style(margin: Margins.only(bottom: 12, left: 20)),
                'ol': Style(margin: Margins.only(bottom: 12, left: 20)),
                'li': Style(margin: Margins.only(bottom: 6)),
              },
            ),
          );
        },
      ),
    );
  }
}
