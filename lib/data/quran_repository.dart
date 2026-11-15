import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/quran.dart';

class QuranRepository {
  Future<QuranData> loadBundled() async {
    final source = await rootBundle.loadString('assets/quran-uthmani.json');
    return compute(_parseBundledQuran, source);
  }
}

QuranData _parseBundledQuran(String source) {
  final response = jsonDecode(source) as Map<String, dynamic>;
  return QuranData.fromApiResponse(response);
}
