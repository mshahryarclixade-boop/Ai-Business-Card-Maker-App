import 'dart:typed_data';

import 'package:http/http.dart' as http;

class FoundLogo {
  const FoundLogo({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class _Candidate {
  const _Candidate(this.url, this.size);

  final String url;
  final int size;
}

class LogoFinder {
  LogoFinder._();

  static const _timeout = Duration(seconds: 8);
  static const _maxBytes = 5 * 1024 * 1024;
  static const _headers = {
    'User-Agent':
    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
  };

  /// Returns the site's logo, or null if none could be found.
  static Future<FoundLogo?> find(String input) async {
    final uri = _normalize(input);
    if (uri == null) return null;

    try {
      final page = await http.get(uri, headers: _headers).timeout(_timeout);
      if (page.statusCode != 200) return null;

      for (final url in _candidates(page.body, uri).take(4)) {
        final logo = await _download(url, uri);
        if (logo != null) return logo;
      }
    } catch (_) {
      // Network error, timeout, bad HTML: treat as "not found".
    }
    return null;
  }

  static Uri? _normalize(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      text = 'https://$text';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return null;
    }
    return uri;
  }

  static String? _attr(String tag, String name) {
    final match = RegExp(
      r'(?:^|\s)' + name + r'''\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(tag);
    return match?.group(1);
  }

  static List<String> _candidates(String html, Uri base) {
    final apple = <_Candidate>[];
    final icons = <_Candidate>[];
    String? ogImage;

    for (final m
    in RegExp(r'<link\b[^>]*>', caseSensitive: false).allMatches(html)) {
      final tag = m.group(0)!;
      final rel = (_attr(tag, 'rel') ?? '').toLowerCase();
      final href = _attr(tag, 'href');
      if (href == null || !rel.contains('icon')) continue;

      // Flutter can't show .svg / .ico without extra packages.
      final path = Uri.tryParse(href)?.path.toLowerCase() ?? '';
      if (path.endsWith('.svg') || path.endsWith('.ico')) continue;

      final size = int.tryParse(
          (_attr(tag, 'sizes') ?? '').toLowerCase().split('x').first) ??
          0;
      final item = _Candidate(base.resolve(href).toString(), size);
      (rel.contains('apple') ? apple : icons).add(item);
    }

    for (final m
    in RegExp(r'<meta\b[^>]*>', caseSensitive: false).allMatches(html)) {
      final tag = m.group(0)!;
      final key =
      (_attr(tag, 'property') ?? _attr(tag, 'name') ?? '').toLowerCase();
      final content = _attr(tag, 'content');
      if (key == 'og:image' && content != null) {
        ogImage = base.resolve(content).toString();
        break;
      }
    }

    apple.sort((a, b) => b.size.compareTo(a.size));
    icons.sort((a, b) => b.size.compareTo(a.size));

    return <String>{
      ...apple.map((c) => c.url),
      ...icons.map((c) => c.url),
      if (ogImage != null) ogImage,
    }.toList();
  }

  static Future<FoundLogo?> _download(String url, Uri site) async {
    try {
      final res =
      await http.get(Uri.parse(url), headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;

      final ext = _extension((res.headers['content-type'] ?? '').toLowerCase());
      if (ext == null) return null;

      final bytes = res.bodyBytes;
      if (bytes.isEmpty || bytes.length > _maxBytes) return null;

      return FoundLogo(bytes: bytes, name: '${_brand(site)} logo.$ext');
    } catch (_) {
      return null;
    }
  }

  static String? _extension(String contentType) {
    if (contentType.contains('png')) return 'png';
    if (contentType.contains('jpeg') || contentType.contains('jpg')) {
      return 'jpg';
    }
    if (contentType.contains('webp')) return 'webp';
    if (contentType.contains('gif')) return 'gif';
    return null;
  }

  static String _brand(Uri uri) {
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    final name = host.split('.').first;
    return name.isEmpty ? 'Company' : name[0].toUpperCase() + name.substring(1);
  }
}