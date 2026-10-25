import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'scanner_screen.dart';
import '../theme/theme.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../services/preference_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _teamNameController = TextEditingController();
  List<TextEditingController> _memberControllers = [];
  
  IconData _selectedIcon = Icons.bolt;
  int? _scannedSlot;
  bool _isRegistering = false;

  final List<IconData> _teamIcons = [
    Icons.bolt, Icons.rocket_launch, Icons.shield, Icons.auto_awesome,
    Icons.diamond, Icons.fort, Icons.workspace_premium, Icons.local_fire_department
  ];

  @override
  void initState() {
    super.initState();
    _teamNameController.addListener(() => setState(() {}));
    _memberControllers = List.generate(3, (index) {
      final controller = TextEditingController();
      controller.addListener(() => setState(() {}));
      return controller;
    });
  }

  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _teamNameController.dispose();
    _pageController.dispose();
    for (var c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _scanQRCode() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    
    if (result != null && mounted) {
      setState(() => _scannedSlot = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم مسح الرمز بنجاح! الفريق رقم $_scannedSlot')),
      );
    }
  }

  Future<void> _enterAsSpectator() async {
    await PreferenceService.setSpectator(true);
    if (mounted) {
      context.read<GameProvider>().setSpectator(true);
    }
  }

  Future<void> _registerTeam() async {
    if (_scannedSlot == null || _teamNameController.text.trim().isEmpty) return;
    
    setState(() => _isRegistering = true);
    try {
      final colorIndex = ((_scannedSlot ?? 1) - 1) % AppColor.teamColors.length;
      final autoColor = AppColor.teamColors[colorIndex];

      final teamData = {
        'name': _teamNameController.text.trim(),
        'members': _memberControllers.map((c) => c.text.trim()).toList(),
        'color': autoColor.toARGB32(),
        'icon_code': _selectedIcon.codePoint,
        'is_registered': true,
        'score': 0,
      };

      await _firebaseService.updateTeamSlot('team_$_scannedSlot', teamData);
      await PreferenceService.saveTeamRegistration(_scannedSlot!, _teamNameController.text.trim(), autoColor.toARGB32());
      
      if (!mounted) return;
      final team = Team(
        name: _teamNameController.text.trim(),
        members: _memberControllers.map((c) => c.text.trim()).toList(),
        teamColor: autoColor,
      );
      context.read<GameProvider>().setTeam(team);
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _firebaseService.gameInfoStream,
        builder: (context, snapshot) {
          final gameData = snapshot.data ?? {};
          final requiredMembers = gameData['team_size'] ?? 3;
          
          if (_memberControllers.length != requiredMembers) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  for (var c in _memberControllers) {
                    c.dispose();
                  }
                  _memberControllers = List.generate(requiredMembers, (index) {
                    final controller = TextEditingController();
                    controller.addListener(() => setState(() {}));
                    return controller;
                  });
                });
              }
            });
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SafeArea(
            child: Column(
              children: [
                _buildProgressHeader(isDark),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _buildScanPage(gameData['num_teams'] ?? 0, gameData['status'] ?? 'idle', isDark),
                      _buildInfoPage(requiredMembers, isDark),
                      _buildIdentityPage(isDark),
                    ],
                  ),
                ),
                _buildNavigationFooter(isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final isDone = _currentStep > index;
              final isCurr = _currentStep == index;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isCurr || isDone ? AppColor.primaryColor : (isDark ? Colors.white10 : Colors.black12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurr ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (index < 2)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone ? AppColor.primaryColor : (isDark ? Colors.white10 : Colors.black12),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _currentStep == 0 ? 'مسح الرمز' : _currentStep == 1 ? 'بيانات الفريق' : 'هوية الفريق',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPage(int maxTeams, String status, bool isDark) {
    final isActive = status != 'idle' && status != 'none';
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.teamsStream,
      builder: (context, snapshot) {
        final teamsMap = snapshot.data ?? {};
        final registeredCount = teamsMap.values.where((t) => t['is_registered'] == true).length;
        final limit = maxTeams > 0 ? maxTeams : (teamsMap.isNotEmpty ? teamsMap.length : 4);
        final vacantSlots = limit - registeredCount;
        final hasVacant = vacantSlots > 0 && isActive;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_scannedSlot == null) ...[
                const Icon(Icons.qr_code_scanner, size: 120, color: AppColor.primaryColor).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                const SizedBox(height: 40),
                const Text('مرحباً بك في المسابقة!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                // Vacant slots badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: !isActive
                        ? Colors.amber.withValues(alpha: 0.1)
                        : (hasVacant ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: !isActive 
                          ? Colors.amber 
                          : (hasVacant ? Colors.green : Colors.redAccent),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    !isActive
                        ? '⚠️ لا توجد مسابقة نشطة حالياً'
                        : (hasVacant ? '🟢 الأماكن الشاغرة: $vacantSlots / $limit' : '🔴 عذراً، جميع الأماكن ممتلئة!'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: !isActive 
                          ? Colors.amber 
                          : (hasVacant ? (isDark ? Colors.greenAccent : Colors.green.shade800) : Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  !isActive
                      ? 'يرجى الانتظار حتى يقوم المسؤول بإطلاق وتفعيل المسابقة لتتمكن من المشاركة.'
                      : (hasVacant 
                          ? 'يرجى مسح رمز الـ QR المخصص لفريقك للمشاركة، أو الدخول كمشاهد لمتابعة التحديات.'
                          : 'المسابقة ممتلئة حالياً بالفرق المشاركة. يمكنك الدخول كمشاهد لمتابعة التحديات والنتائج مباشرة!'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.getTextSecondary(context)),
                ),
                const SizedBox(height: 40),
                
                if (isActive && hasVacant) ...[
                  ElevatedButton.icon(
                    onPressed: _scanQRCode,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ابدأ مسح الرمز للمشاركة'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 60),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _enterAsSpectator,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('الدخول كمشاهد فقط'),
                    style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white38 : Colors.black45),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _enterAsSpectator,
                    icon: const Icon(Icons.visibility),
                    label: const Text('الدخول كمشاهد لمتابعة التحدي'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 60),
                      backgroundColor: AppColor.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                    ),
                  ),
                ],
              ] else ...[
                const Icon(Icons.verified, size: 100, color: AppColor.correctColor).animate().scale(),
                const SizedBox(height: 24),
                Text('تم التحقق من الفريق رقم $_scannedSlot', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('يمكنك الآن المتابعة لإدخال بيانات الفريق', style: TextStyle(color: AppColor.getTextSecondary(context))),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => setState(() => _scannedSlot = null),
                  child: Text('إعادة المسح؟', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPage(int requiredMembers, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اسم الفريق', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _teamNameController, decoration: const InputDecoration(hintText: 'أدخل اسم الفريق هنا...', prefixIcon: Icon(Icons.groups))),
          const SizedBox(height: 32),
          const Text('أعضاء الفريق', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(requiredMembers, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(controller: _memberControllers[index], decoration: InputDecoration(hintText: 'اسم العضو ${index + 1}', prefixIcon: const Icon(Icons.person_outline))),
          )),
        ],
      ),
    );
  }

  Widget _buildIdentityPage(bool isDark) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firebaseService.teamsStream,
      builder: (context, snapshot) {
        final teams = snapshot.data ?? {};
        final takenIcons = teams.values.where((t) => t['is_registered'] == true).map((t) => t['icon_code'] as int?).toSet();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('شعار الفريق', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: _teamIcons.map((icon) {
                  final isTaken = takenIcons.contains(icon.codePoint);
                  final isSel = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: isTaken ? null : () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColor.primaryColor
                            : (isTaken
                                ? (isDark ? Colors.black26 : Colors.black12)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04))),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel
                              ? AppColor.primaryColor
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            icon,
                            color: isSel
                                ? Colors.white
                                : (isTaken
                                    ? (isDark ? Colors.white12 : Colors.black12)
                                    : (isDark ? Colors.white : Colors.black87)),
                            size: 24,
                          ),
                          if (isTaken && !isSel) const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text('لون الفريق (تم تخصيصه تلقائياً)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColor.teamColors[((_scannedSlot ?? 1) - 1) % AppColor.teamColors.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColor.teamColors[((_scannedSlot ?? 1) - 1) % AppColor.teamColors.length].withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                  ]
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationFooter(bool isDark) {
    final allMembersFilled = _memberControllers.isNotEmpty && _memberControllers.every((c) => c.text.trim().isNotEmpty);
    final canGoNext = _currentStep == 0 
        ? _scannedSlot != null 
        : _currentStep == 1 
            ? (_teamNameController.text.trim().isNotEmpty && allMembersFilled) 
            : true;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColor.surfaceColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 55)),
                child: const Text('السابق'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !canGoNext ? null : (_currentStep == 2 ? (_isRegistering ? null : _registerTeam) : _nextPage),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 55),
                backgroundColor: canGoNext
                    ? AppColor.primaryColor
                    : (isDark ? Colors.white10 : Colors.black12),
                elevation: 4,
              ),
              child: _isRegistering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _currentStep == 2 ? 'إتمام التسجيل' : 'التالي',
                      style: TextStyle(
                        color: canGoNext
                            ? Colors.white
                            : (isDark ? Colors.white24 : Colors.black26),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
