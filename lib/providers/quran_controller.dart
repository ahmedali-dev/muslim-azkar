import 'package:flutter/foundation.dart';

import '../data/quran_repository.dart';
import '../models/quran.dart';

class QuranController extends ChangeNotifier {
  QuranController(this.repository);

  final QuranRepository repository;
  QuranData? data;
  bool loading = false;
  String? error;

  Future<void> load() async {
    if (loading || data != null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await repository.loadBundled();
    } catch (_) {
      error =
          'تعذّر فتح نسخة القرآن المضمّنة. أعد المحاولة أو أعد تثبيت التطبيق.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
