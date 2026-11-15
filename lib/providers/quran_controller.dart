import 'package:flutter/foundation.dart';

import '../data/quran_repository.dart';
import '../models/quran.dart';

class QuranController extends ChangeNotifier {
  QuranController(this.repository);

  final QuranRepository repository;
  QuranData? data;
  bool loading = false;
  bool refreshing = false;
  String? error;

  bool get busy => loading || refreshing;

  Future<void> load() async {
    if (busy || data != null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await repository.readCache();
    } catch (_) {
      data = null;
    }
    if (data != null) {
      loading = false;
      notifyListeners();
      return;
    }
    loading = false;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    if (busy) return;
    refreshing = true;
    error = null;
    notifyListeners();
    try {
      data = await repository.download();
    } catch (_) {
      error = data == null
          ? 'تعذّر تحميل نص القرآن. تحقق من الاتصال ثم أعد المحاولة.'
          : 'تعذّر التحديث؛ يمكنك المتابعة بالنص المحفوظ على جهازك.';
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
