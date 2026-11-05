import 'package:flutter/material.dart';
import '../widgets/ornament.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({
    super.key,
    required this.onReview,
    required this.onRestart,
  });
  final VoidCallback onReview;
  final VoidCallback onRestart;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Ornament(size: 130, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            'تقبّل الله منك',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'اللهم اجعل ذِكرك نورًا لقلوبنا،\nوسكينةً لأرواحنا، وبركةً في أيامنا.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 26, height: 1.9),
          ),
          const SizedBox(height: 20),
          const Text('أتممت قراءتك لهذا اليوم'),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('العودة للرئيسية'),
          ),
          TextButton(onPressed: onReview, child: const Text('مراجعة الأذكار')),
          TextButton(onPressed: onRestart, child: const Text('البدء من جديد')),
        ],
      ),
    ),
  );
}
