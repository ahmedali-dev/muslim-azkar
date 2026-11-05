import 'package:flutter/material.dart';
import '../widgets/glass_surface.dart';
import 'package:provider/provider.dart';
import '../models/zikr.dart';
import '../providers/app_state.dart';
import '../widgets/category_icon.dart';
import 'azkar_screen.dart';

String _searchText(String text) => text
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .trim();

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final query = _searchText(_search.text);
    final categories = AzkarPeriod.values
        .where(
          (category) =>
              state.content.containsKey(category) &&
              _searchText(category.title).contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const GlassSurface(radius: 0, child: SizedBox.expand()),
        title: const Text('جميع الأذكار والأدعية'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    key: const ValueKey('categorySearch'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن قسم',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(_search.clear),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        'الأقسام: ${categories.length}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('محفوظة على جهازك'),
                    ],
                  ),
                ),
                Expanded(
                  child: categories.isEmpty
                      ? const Center(child: Text('لا يوجد قسم مطابق لبحثك'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: categories.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final percent = (state.fraction(category) * 100)
                                .round();
                            return GlassCard(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                key: ValueKey('category-${category.sourceId}'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                leading: Icon(
                                  categoryIcon(category),
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(
                                  category.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'النصوص: ${state.content[category]!.length} • التقدم: $percent٪',
                                  ),
                                ),
                                trailing: Icon(
                                  percent == 100
                                      ? Icons.check_circle_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AzkarScreen(period: category),
                                  ),
                                ),
                              ),
                            );
                          },
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
