import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/zikr.dart';

class AzkarRepository {
  static Future<Map<AzkarPeriod, List<Zikr>>> load() async {
    final result = <AzkarPeriod, List<Zikr>>{};
    for (final period in AzkarPeriod.values) {
      final raw = await rootBundle.loadString(period.assetPath);
      result[period] = (jsonDecode(raw) as List)
          .map((e) => Zikr.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return result;
  }
}
