import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zikr.dart';
import '../providers/app_state.dart';
import '../widgets/glass_surface.dart';
import '../widgets/period_card.dart';
import 'about_screen.dart';
import 'categories_screen.dart';
import 'azkar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final hour = state.now.hour;
    void library() => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
    );
    Widget card(AzkarPeriod period, {required bool featured}) => PeriodCard(
      period: period,
      featured: featured,
      progress: state.fraction(period),
      count: state.content[period]!.length,
      highlighted: period == AzkarPeriod.morning
          ? hour < 12
          : hour * 60 + state.now.minute >= state.settings.asrMinutes,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => AzkarScreen(period: period)),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكار المسلم'),
        leading: IconButton(
          tooltip: 'حول التطبيق',
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'جميع الأقسام',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: library,
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) library();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'الأذكار',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              children: [
                Text(
                  hour < 12 ? 'صباحٌ يملؤه الذكر' : 'مساؤك طمأنينة',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'طمأنينةٌ لقلبك',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 34,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لحظاتٌ من الذكر، وأثرٌ يبقى معك.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (state.storageError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.storageError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final featured = dark
                        ? AzkarPeriod.evening
                        : AzkarPeriod.morning;
                    final other = dark
                        ? AzkarPeriod.morning
                        : AzkarPeriod.evening;
                    if (constraints.maxWidth >= 650) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: card(AzkarPeriod.morning, featured: true),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: card(AzkarPeriod.evening, featured: true),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        card(featured, featured: true),
                        const SizedBox(height: 12),
                        card(other, featured: false),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.menu_book_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text(
                      'تصفّح جميع الأقسام',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'الأقسام: ${state.content.length} • النصوص: ${state.content.values.fold<int>(0, (sum, items) => sum + items.length)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onTap: library,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'على مهل… كل تسبيحة خطوة إلى السكينة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    height: 1.8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'يُحفظ تقدمك تلقائيًا لهذا اليوم',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
