import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glass_app_bar.dart';
import '../../services/firebase_service.dart';
import '../../models/question_model.dart';
import '../../theme/theme.dart';

class CreateCompetitionScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? existingKey;

  const CreateCompetitionScreen({super.key, this.existingData, this.existingKey});

  @override
  State<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

/// أسماء واجهات المراحل — كل نوع يفتح شاشة خاصة عند اللاعبين
const Map<String, String> _stageTypeLabels = {
  'arena': 'المواجهة',
  'fast_answer': 'السرعة',
  'direct_question': 'سؤال مباشر',
  'who_am_i': 'من أنا؟',
  'wager': 'المجازفة',
  'tunnel': 'النفق',
};

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isEditMode = false;
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  int _numTeams = 4;
  int _teamSize = 3;

  List<Map<String, dynamic>> _stages = [
    {'name': 'الجولة الأولى', 'type': 'arena', 'questions': <QuestionModel>[]},
    {'name': 'الجولة الثانية', 'type': 'arena', 'questions': <QuestionModel>[]},
    {'name': 'الجولة النهائية', 'type': 'arena', 'questions': <QuestionModel>[]},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _isEditMode = true;
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    final data = widget.existingData!;
    _titleController.text = data['title'] ?? '';
    _dateController.text = data['date'] ?? '';
    _numTeams = data['num_teams'] ?? 4;
    _teamSize = data['team_size'] ?? 3;

    // Load stages with questions from Firebase
    final rawStages = data['stages'] as List? ?? [];
    final allQuestions = await _firebaseService.getQuestionsOnce();

    _stages = rawStages.map((s) {
      final stage = Map<String, dynamic>.from(s);
      final qIds = List<String>.from(stage['question_ids'] ?? []);
      final questions = <QuestionModel>[];
      for (final qId in qIds) {
        final match = allQuestions.where((q) => q.id == qId);
        if (match.isNotEmpty) questions.add(match.first);
      }
      return {
        'name': stage['name'] ?? 'مرحلة',
        'type': stage['type'] ?? 'fast_answer',
        'questions': questions,
      };
    }).toList();

    setState(() => _isLoading = false);
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishCreation({required bool launchImmediately}) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال عنوان المسابقة')));
      return;
    }
    
    if (_stages.any((s) => (s['questions'] as List).isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار أسئلة لجميع المراحل')));
      return;
    }

    final userProvider = context.read<UserProvider>();
    final creatorId = userProvider.matricule;
    final creatorName = userProvider.fullNameAr.isNotEmpty ? userProvider.fullNameAr : 'مشرف';

    final competitionData = {
      'title': _titleController.text.trim(),
      'date': _dateController.text.trim(),
      'status': launchImmediately ? 'waiting' : 'saved',
      'num_teams': _numTeams,
      'team_size': _teamSize,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'stages': _stages.map((s) => {
        'name': s['name'],
        'type': s['type'],
        'question_ids': (s['questions'] as List<QuestionModel>).map((q) => q.id).toList(),
      }).toList(),
      'current_stage_index': 0,
      'current_question_index': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    // If editing, delete old key first if title changed
    if (_isEditMode && widget.existingKey != null && widget.existingKey != _titleController.text.trim()) {
      await _firebaseService.deleteCompetitionFromLibrary(widget.existingKey!);
    }

    // Save to library
    await _firebaseService.saveToLibrary(competitionData['title'] as String, competitionData);

    if (launchImmediately) {
      await _firebaseService.updateGameState(
        status: 'waiting',
        title: competitionData['title'] as String,
        date: competitionData['date'] as String,
        numTeams: _numTeams,
        teamSize: _teamSize,
        stages: (competitionData['stages'] as List).cast<Map<String, dynamic>>(),
        creatorId: creatorId,
        creatorName: creatorName,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(launchImmediately 
          ? 'تم إطلاق المسابقة بنجاح' 
          : (_isEditMode ? 'تم حفظ التعديلات' : 'تم حفظ المسابقة في المكتبة')))
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: GlassAppBar(
        title: Text(_isEditMode ? 'تعديل المسابقة' : 'تجهيز مسابقة جديدة'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primaryColor))
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBasicInfoStep(),
                      _buildStagesStep(),
                      _buildReviewStep(),
                    ],
                  ),
                ),
                _buildNavigation(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isActive ? AppColor.primaryColor : Colors.white10,
                  child: Text('${index + 1}', style: TextStyle(color: isActive ? Colors.black : Colors.white30, fontSize: 12)),
                ),
                if (index < 2)
                  Expanded(child: Container(height: 2, color: index < _currentStep ? AppColor.primaryColor : Colors.white10)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('المعلومات الأساسية'),
          const SizedBox(height: 24),
          _textField(_titleController, 'عنوان المسابقة (مثال: دورة الربيع)'),
          const SizedBox(height: 16),
          _textField(_dateController, 'التاريخ (مثال: 15 ماي 2026)'),
          const SizedBox(height: 32),
          _sectionTitle('إعدادات الفرق'),
          const SizedBox(height: 16),
          _buildCounter('عدد الفرق المشاركة', _numTeams, (val) => setState(() => _numTeams = val)),
          const SizedBox(height: 12),
          _buildCounter('عدد الأعضاء في كل فريق', _teamSize, (val) => setState(() => _teamSize = val)),
        ],
      ),
    );
  }

  Widget _buildStagesStep() {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _stages.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = _stages.removeAt(oldIndex);
                _stages.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final stage = _stages[index];
              final qs = stage['questions'] as List<QuestionModel>;
              return Card(
                key: ValueKey('stage_$index'),
                color: AppColor.surfaceColor,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.drag_handle, color: Colors.white24, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _editStageName(index),
                              child: Row(
                                children: [
                                  Flexible(child: Text(stage['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit, size: 14, color: Colors.white38),
                                ],
                              ),
                            ),
                          ),
                          if (_stages.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _removeStage(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // واجهة المرحلة — كي يختارها الأدمين تتبدل شاشة اللاعبين تلقائياً
                      Row(
                        children: [
                          const Icon(Icons.tv_outlined,
                              color: Colors.white38, size: 16),
                          const SizedBox(width: 8),
                          const Text('واجهة المرحلة',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _stageTypeLabels.containsKey(
                                          stage['type']?.toString())
                                      ? stage['type'] as String
                                      : 'arena',
                                  isExpanded: true,
                                  dropdownColor: AppColor.surfaceColor,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                  items: _stageTypeLabels.entries
                                      .map((e) => DropdownMenuItem(
                                          value: e.key, child: Text(e.value)))
                                      .toList(),
                                  onChanged: (v) => setState(() =>
                                      _stages[index]['type'] = v ?? 'arena'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (qs.isEmpty)
                        const Text('لم يتم اختيار أسئلة بعد', style: TextStyle(color: Colors.white24, fontSize: 13))
                      else
                        Column(
                          children: [
                            Text('${qs.length} أسئلة مختارة', style: const TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...qs.asMap().entries.map((entry) => Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text('${entry.key + 1}.', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(entry.value.questionText, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  GestureDetector(
                                    onTap: () => setState(() => qs.removeAt(entry.key)),
                                    child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showQuestionPicker(index),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('اختيار الأسئلة'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addStage,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مرحلة جديدة'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColor.primaryColor),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addStage() {
    setState(() {
      _stages.add({
        'name': 'مرحلة ${_stages.length + 1}',
        'type': 'arena',
        'questions': <QuestionModel>[],
      });
    });
  }

  void _removeStage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المرحلة'),
        content: Text('هل تريد حذف "${_stages[index]['name']}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() => _stages.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _editStageName(int index) {
    final controller = TextEditingController(text: _stages[index]['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم المرحلة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اسم المرحلة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _stages[index]['name'] = controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }



  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('مراجعة المسابقة'),
          const SizedBox(height: 24),
          _reviewItem('العنوان', _titleController.text),
          _reviewItem('التاريخ', _dateController.text),
          _reviewItem('الفرق', '$_numTeams فرق (كل فريق $_teamSize أعضاء)'),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          ..._stages.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColor.primaryColor, size: 16),
                const SizedBox(width: 12),
                Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${(s['questions'] as List).length} سؤال', style: const TextStyle(color: Colors.white38)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColor.surfaceColor, border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(child: OutlinedButton(onPressed: _prevPage, child: const Text('السابق'))),
          if (_currentStep > 0) const SizedBox(width: 16),
          if (_currentStep == 2) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _finishCreation(launchImmediately: false),
                child: Text(_isEditMode ? 'حفظ التعديلات' : 'حفظ فقط', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep == 2 ? 1 : 2,
            child: ElevatedButton(
              onPressed: () => _currentStep == 2 ? _finishCreation(launchImmediately: true) : _nextPage(),
              child: Text(_currentStep == 2 ? 'إطلاق الآن' : 'التالي'),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestionPicker(int stageIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StreamBuilder<List<QuestionModel>>(
          stream: _firebaseService.getQuestionsStream(),
          builder: (context, snapshot) {
            final allQs = snapshot.data ?? [];
            final selectedOnes = List<QuestionModel>.from(_stages[stageIndex]['questions']);
            
            return Column(
              children: [
                const SizedBox(height: 20),
                const Text('بنك الأسئلة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: allQs.length,
                    itemBuilder: (context, i) {
                      final q = allQs[i];
                      final isSel = selectedOnes.any((s) => s.id == q.id);
                      return CheckboxListTile(
                        value: isSel,
                        title: Text(q.questionText),
                        subtitle: Text(q.category, style: const TextStyle(color: AppColor.primaryColor, fontSize: 12)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _stages[stageIndex]['questions'].add(q);
                            } else {
                              _stages[stageIndex]['questions'].removeWhere((s) => s.id == q.id);
                            }
                          });
                          (context as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.primaryColor, letterSpacing: 1.2));
  }

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        IconButton(onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
        Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(onPressed: value < 10 ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
