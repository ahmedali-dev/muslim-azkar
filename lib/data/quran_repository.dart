import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/quran.dart';

class QuranRepository {
  QuranRepository({
    http.Client? client,
    Future<Directory> Function()? supportDirectory,
  }) : _client = client ?? http.Client(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static final _uri = Uri.https(
    'api.alquran.cloud',
    '/v1/quran/quran-uthmani-quran-academy',
  );

  final http.Client _client;
  final Future<Directory> Function() _supportDirectory;

  Future<File> _cacheFile() async {
    final directory = await _supportDirectory();
    return File('${directory.path}/quran-uthmani-quran-academy.json');
  }

  Future<QuranData?> readCache() async {
    final file = await _cacheFile();
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return QuranData.fromApiResponse(json);
    } catch (_) {
      try {
        await file.delete();
      } catch (_) {
        // A stale cache must never block downloading a verified copy.
      }
      return null;
    }
  }

  Future<QuranData> download() async {
    final response = await _client
        .get(_uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Quran API returned ${response.statusCode}.');
    }
    final body = utf8.decode(response.bodyBytes);
    final json = jsonDecode(body) as Map<String, dynamic>;
    final quran = QuranData.fromApiResponse(json);
    try {
      final file = await _cacheFile();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.download');
      await temporary.writeAsBytes(response.bodyBytes, flush: true);
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    } catch (_) {
      // Keep the verified response available for this session if storage fails.
    }
    return quran;
  }

  void dispose() => _client.close();
}
