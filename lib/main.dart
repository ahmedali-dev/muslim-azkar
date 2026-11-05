import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/azkar_repository.dart';
import 'models/zikr.dart';
import 'providers/app_state.dart';
import 'screens/azkar_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_surface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in {'Amiri': 'خط أميري', 'Tajawal': 'خط تجوال'}.entries) {
      final text = await rootBundle.loadString(
        'assets/fonts/${font.key}-OFL.txt',
      );
      yield LicenseEntryWithLineBreaks([font.value], text);
    }
  });
  final prefs = await SharedPreferences.getInstance();
  final content = await AzkarRepository.load();
  final notifications = NotificationService();
  // A platform notification failure must never prevent offline reading.
  try {
    await notifications.initialize();
  } catch (_) {
    notifications.available = false;
  }
  final state = AppState(prefs, content);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        Provider.value(value: notifications),
      ],
      child: const MuslimAzkarApp(),
    ),
  );
}

class MuslimAzkarApp extends StatefulWidget {
  const MuslimAzkarApp({super.key});
  @override
  State<MuslimAzkarApp> createState() => _MuslimAzkarAppState();
}

class _MuslimAzkarAppState extends State<MuslimAzkarApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  // Theme generation is expensive and independent of counter progress.
  final _lightTheme = appTheme(Brightness.light);
  final _darkTheme = appTheme(Brightness.dark);
  bool _synchronizing = false;
  late NotificationService _notifications;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final service = context.read<NotificationService>();
    _notifications = service;
    service.onOpen = _open;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (service.initialPeriod != null) {
        _open(service.initialPeriod!);
        service.initialPeriod = null;
      }
      unawaited(_synchronize());
    });
  }

  void _open(AzkarPeriod p) {
    _navigator.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => AzkarScreen(period: p)),
      (route) => route.isFirst,
    );
  }

  Future<void> _synchronize() async {
    if (_synchronizing) return;
    _synchronizing = true;
    try {
      await context.read<NotificationService>().synchronize(
        context.read<AppState>().settings,
      );
    } catch (_) {
      /* Settings allow a manual retry without blocking reading. */
    } finally {
      _synchronizing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().ensureToday();
      unawaited(_synchronize());
    } else if (state == AppLifecycleState.paused) {
      unawaited(context.read<AppState>().flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.onOpen = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    debugShowCheckedModeBanner: false,
    title: 'أذكار المسلم',
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: _lightTheme,
    darkTheme: _darkTheme,
    themeMode: context.select<AppState, ThemeMode>(
      (state) => state.settings.themeMode,
    ),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: GlassBackdrop(child: child!),
    ),
    home: const HomeScreen(),
  );
}
