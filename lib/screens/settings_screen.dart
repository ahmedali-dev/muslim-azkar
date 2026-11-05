import 'package:flutter/material.dart';
import '../widgets/glass_surface.dart';
import 'package:provider/provider.dart';
import '../models/zikr.dart';
import '../providers/app_state.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  Future<void> _reminder(AzkarPeriod p, bool enabled, int minutes) async {
    if (_busy) return;
    final state = context.read<AppState>();
    final service = context.read<NotificationService>();
    setState(() => _busy = true);
    try {
      if (!service.available) throw StateError('Notifications unavailable');
      ReminderResult? result;
      if (enabled) {
        result = await service.schedule(p, minutes, requestPermissions: true);
        if (result == ReminderResult.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'اسمح بالإشعارات من إعدادات الجهاز لتفعيل التذكير.',
                ),
              ),
            );
          }
          return;
        }
      } else {
        await service.cancel(p);
      }
      state.updateSettings((s) => s.setReminder(p, enabled, minutes));
      if (mounted && result == ReminderResult.approximate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم التفعيل. قد يتأخر التذكير دون إذن المنبّهات الدقيقة.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر ضبط التذكير. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const GlassSurface(radius: 0, child: SizedBox.expand()),
        title: const Text('الإعدادات'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                heading('لحظة للذكر، كل يوم'),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final p in AzkarPeriod.reminderPeriods) ...[
                        SwitchListTile(
                          title: Text('تذكير ${p.title}'),
                          secondary: Icon(
                            p == AzkarPeriod.morning
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_round,
                          ),
                          value: settings.enabled(p),
                          onChanged: _busy
                              ? null
                              : (v) => _reminder(p, v, settings.minutes(p)),
                        ),
                        ListTile(
                          title: const Text('وقت التذكير'),
                          subtitle: Text(
                            TimeOfDay(
                              hour: settings.minutes(p) ~/ 60,
                              minute: settings.minutes(p) % 60,
                            ).format(context),
                          ),
                          trailing: const Icon(Icons.schedule_rounded),
                          enabled: !_busy,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: settings.minutes(p) ~/ 60,
                                minute: settings.minutes(p) % 60,
                              ),
                              helpText: 'اختر وقت التذكير',
                              cancelText: 'إلغاء',
                              confirmText: 'حفظ',
                            );
                            if (time == null || !context.mounted) return;
                            final minutes = time.hour * 60 + time.minute;
                            if (settings.enabled(p)) {
                              await _reminder(p, true, minutes);
                            } else {
                              state.updateSettings(
                                (s) => s.setReminder(p, false, minutes),
                              );
                            }
                          },
                        ),
                        if (p == AzkarPeriod.morning)
                          const Divider(indent: 20, endIndent: 20),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'يُطلب إذن الإشعارات عند تفعيل التذكير فقط. المنبّهات الدقيقة اختيارية لضبط الموعد.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: const Text('وقت العصر في مدينتك'),
                    subtitle: Text(
                      'لتمييز بطاقة المساء: ${TimeOfDay(hour: settings.asrMinutes ~/ 60, minute: settings.asrMinutes % 60).format(context)}',
                    ),
                    trailing: const Icon(Icons.wb_twilight_rounded),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.asrMinutes ~/ 60,
                          minute: settings.asrMinutes % 60,
                        ),
                        helpText: 'وقت العصر المحلي',
                        cancelText: 'إلغاء',
                        confirmText: 'حفظ',
                      );
                      if (time == null || !context.mounted) return;
                      if (time.hour < 12) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('اختر وقتًا بعد الظهر.'),
                          ),
                        );
                        return;
                      }
                      state.updateSettings(
                        (s) => s.asrMinutes = time.hour * 60 + time.minute,
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'اضبط وقت العصر المحلي حسب مدينتك. لا يستخدم التطبيق موقعك ولا يحسب مواقيت الصلاة.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                heading('قراءة مريحة'),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'حجم خط الأذكار',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in {
                              0: 'صغير',
                              1: 'متوسط',
                              2: 'كبير',
                            }.entries)
                              ChoiceChip(
                                label: Text(entry.value),
                                selected: settings.fontLevel == entry.key,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                onSelected: (_) => state.updateSettings(
                                  (s) => s.fontLevel = entry.key,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: settings.fontSize,
                            height: 1.8,
                            color: theme.colorScheme.onSurface,
                          ),
                          child: const Text(
                            'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                heading('كما تحب'),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<ThemeMode>(
                          isExpanded: true,
                          value: settings.themeMode,
                          decoration: const InputDecoration(
                            labelText: 'مظهر التطبيق',
                            prefixIcon: Icon(Icons.palette_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('حسب النظام'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('فاتح'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('داكن'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              state.updateSettings((s) => s.themeMode = value);
                            }
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('الاهتزاز عند العدّ'),
                        secondary: const Icon(Icons.vibration_rounded),
                        value: settings.vibration,
                        onChanged: (value) =>
                            state.updateSettings((s) => s.vibration = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
