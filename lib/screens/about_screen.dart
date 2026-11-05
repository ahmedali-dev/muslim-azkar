import 'package:flutter/material.dart';
import '../widgets/glass_surface.dart';
import '../widgets/ornament.dart';
import '../models/zikr.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const GlassSurface(radius: 0, child: SizedBox.expand()),
      title: const Text('حول التطبيق'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Ornament(
                  size: 110,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Text(
                'أذكار المسلم',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Text('الإصدار ١.٤.١', textAlign: TextAlign.center),
              const SizedBox(height: 28),
              const Text(
                'رفيقك للأذكار والأدعية في ٢٧ قسمًا، يعمل بالكامل دون إنترنت.\n'
                'لا إعلانات، ولا تتبّع، ولا جمع للبيانات. يُحفظ تقدمك وإعداداتك على جهازك فقط.',
                style: TextStyle(fontSize: 17, height: 1.8),
              ),
              const SizedBox(height: 24),
              const Text(
                'مصدر الأذكار',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'النصوص والتكرارات والفضائل من موقع إسلام بوك. نُقلت كما وردت في صفحات المصدر بتاريخ ٢ نوفمبر ٢٠٢٦؛ لا تُضاف أحكام على الروايات داخل التطبيق.',
                style: TextStyle(height: 1.8),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('روابط الأقسام ومصادرها'),
                children: [
                  for (final category in AzkarPeriod.values)
                    ListTile(
                      title: Text(category.title),
                      subtitle: SelectableText(
                        category.sourceUrl,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 12, height: 1.6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'الواجهة بخط تجوال، والأذكار بخط أميري.\nالخطوط مضمّنة بترخيص الخطوط المفتوحة.',
                style: TextStyle(height: 1.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'يبدأ تمييز بطاقة المساء بعد وقت العصر الذي تضبطه في الإعدادات (٤ عصرًا افتراضيًا). لا يحسب التطبيق مواقيت الصلاة ولا يستخدم موقعك.',
                style: TextStyle(height: 1.8),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'أذكار المسلم',
                  applicationVersion: '١.٤.١',
                ),
                child: const Text('تراخيص البرمجيات'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
