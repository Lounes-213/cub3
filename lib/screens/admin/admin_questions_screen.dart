import 'package:flutter/material.dart';
import '../../widgets/glass_app_bar.dart';
import '../../services/firebase_service.dart';
import '../../models/question_model.dart';
import '../../theme/theme.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  void _showQuestionDialog({QuestionModel? question}) {
    final isEditing = question != null;
    final categoryController = TextEditingController(text: question?.category ?? '');
    final textController = TextEditingController(text: question?.questionText ?? '');
    final option1Controller = TextEditingController(text: question?.options.isNotEmpty == true ? question!.options[0] : '');
    final option2Controller = TextEditingController(text: (question?.options.length ?? 0) > 1 ? question!.options[1] : '');
    final option3Controller = TextEditingController(text: (question?.options.length ?? 0) > 2 ? question!.options[2] : '');
    final option4Controller = TextEditingController(text: (question?.options.length ?? 0) > 3 ? question!.options[3] : '');
    String? correctAns = question?.correctAnswer;
    final explanationController = TextEditingController(text: question?.explanation ?? '');
    final hint1Controller = TextEditingController(text: question?.hint1 ?? '');
    final hint2Controller = TextEditingController(text: question?.hint2 ?? '');
    final hint3Controller = TextEditingController(text: question?.hint3 ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final options = [
            option1Controller.text.trim(),
            option2Controller.text.trim(),
            option3Controller.text.trim(),
            option4Controller.text.trim(),
          ].where((o) => o.isNotEmpty).toList();

          return AlertDialog(
            backgroundColor: AppColor.surfaceColor,
            title: Text(isEditing ? 'تعديل السؤال' : 'إضافة سؤال جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(categoryController, 'التصنيف (مثال: إسلاميات)'),
                  _buildTextField(textController, 'نص السؤال', maxLines: 3),
                  const Divider(color: Colors.white24, height: 32),
                  const Text('الخيارات المتاحة:', style: TextStyle(fontSize: 12, color: AppColor.primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(option1Controller, 'الخيار 1', onChanged: (_) => setDialogState(() {})),
                  _buildTextField(option2Controller, 'الخيار 2', onChanged: (_) => setDialogState(() {})),
                  _buildTextField(option3Controller, 'الخيار 3', onChanged: (_) => setDialogState(() {})),
                  _buildTextField(option4Controller, 'الخيار 4', onChanged: (_) => setDialogState(() {})),
                  const Divider(color: Colors.white24, height: 32),
                  const Text('الإجابة الصحيحة:', style: TextStyle(fontSize: 12, color: AppColor.correctColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (options.isEmpty)
                    const Text('يرجى إدخال الخيارات أولاً لتتمكن من اختيار الإجابة الصحيحة', style: TextStyle(fontSize: 10, color: Colors.white38))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: options.contains(correctAns) ? correctAns : null,
                          isExpanded: true,
                          hint: const Text('اختر الإجابة الصحيحة من القائمة', style: TextStyle(fontSize: 12)),
                          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (val) => setDialogState(() => correctAns = val),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildTextField(explanationController, 'الشرح/التعليل (اختياري)', maxLines: 2),
                  const Divider(color: Colors.white24, height: 32),
                  const Text('تلميحات (لمرحلة من أنا؟)', style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                  _buildTextField(hint1Controller, 'التلميح 1'),
                  _buildTextField(hint2Controller, 'التلميح 2'),
                  _buildTextField(hint3Controller, 'التلميح 3'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: (correctAns == null || options.isEmpty) ? null : () {
                  final newQuestion = QuestionModel(
                    category: categoryController.text.trim(),
                    questionText: textController.text.trim(),
                    options: options,
                    correctAnswer: correctAns!,
                    explanation: explanationController.text.trim(),
                    hint1: hint1Controller.text.trim(),
                    hint2: hint2Controller.text.trim(),
                    hint3: hint3Controller.text.trim(),
                  );

                  if (isEditing) {
                    _firebaseService.updateQuestion(question.id!, newQuestion);
                  } else {
                    _firebaseService.addQuestion(newQuestion);
                  }
                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'تحديث' : 'إضافة'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('إدارة بنك الأسئلة'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: _firebaseService.getQuestionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allQuestions = snapshot.data ?? [];
          final categories = ['الكل', ...allQuestions.map((q) => q.category).toSet()];
          
          final questions = allQuestions.where((q) {
            final matchesCat = _selectedCategory == 'الكل' || q.category == _selectedCategory;
            final matchesSearch = q.questionText.contains(_searchQuery) || q.category.contains(_searchQuery);
            return matchesCat && matchesSearch;
          }).toList();

          return Column(
            children: [
              _buildFilterBar(categories),
              Expanded(
                child: questions.isEmpty 
                  ? _buildEmptyState(allQuestions.isEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return _buildQuestionCard(q);
                      },
                    ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuestionDialog(),
        label: const Text('إضافة سؤال'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'بحث في الأسئلة...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 12, color: isSel ? Colors.black : Colors.white70)),
                    selected: isSel,
                    selectedColor: AppColor.primaryColor,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    onSelected: (sel) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q) {
    return Card(
      color: AppColor.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        title: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildChip(q.category, AppColor.primaryColor),
              const SizedBox(width: 8),
              _buildChip('${q.options.length} خيارات', Colors.white24),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white10),
                const Text('الخيارات:', style: TextStyle(fontSize: 12, color: AppColor.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...q.options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(opt == q.correctAnswer ? Icons.check_circle : Icons.circle_outlined, 
                           color: opt == q.correctAnswer ? AppColor.correctColor : Colors.white24, size: 16),
                      const SizedBox(width: 12),
                      Text(opt, style: TextStyle(color: opt == q.correctAnswer ? AppColor.correctColor : Colors.white70, fontSize: 13)),
                    ],
                  ),
                )),
                if (q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('الشرح:', style: TextStyle(fontSize: 12, color: AppColor.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(q.explanation, style: const TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showQuestionDialog(question: q),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(q),
                      icon: const Icon(Icons.delete, size: 16, color: AppColor.wrongColor),
                      label: const Text('حذف', style: TextStyle(color: AppColor.wrongColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(QuestionModel q) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السؤال؟'),
        content: const Text('هل أنت متأكد من حذف هذا السؤال نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              _firebaseService.deleteQuestion(q.id!);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColor.wrongColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDataEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(isDataEmpty ? 'لا توجد أسئلة في البنك' : 'لا توجد نتائج مطابقة للبحث', style: const TextStyle(color: AppColor.textSecondary)),
          if (isDataEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _firebaseService.seedQuestions(),
              child: const Text('استيراد الأسئلة الافتراضية'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
