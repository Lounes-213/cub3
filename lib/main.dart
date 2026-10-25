import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/cloudflare_service.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';
import 'providers/app_config_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/product_share_page.dart';
import 'services/marketplace_service.dart';
import 'models/marketplace_item.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    CloudflareService();
  } catch (_) {}

  NotificationService.init();
  NotificationService.checkOnEntry();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
      ],
      child: const MusabaqatApp(),
    ),
  );
}

/// يستخرج معرّف الغرض من رابط المشاركة (`/p/<id>` أو `/product/<id>`...).
String? extractProductIdFromUri(Uri uri) {
  final seg = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final frag = uri.fragment.replaceFirst(RegExp(r'^#?/?'), '');
  final fragSeg = frag.split('/').where((s) => s.isNotEmpty).toList();

  for (final combined in <List<String>>[seg, fragSeg]) {
    for (int i = 0; i < combined.length; i++) {
      final s = combined[i].toLowerCase();
      if ((s == 'p' || s == 'product' || s == 'produit') &&
          i + 1 < combined.length) {
        final id = Uri.decodeComponent(combined[i + 1]);
        if (id.isNotEmpty) return id;
      }
    }
  }
  return null;
}

/// فتح صفحة الغرض المستقلة إذا فُتح التطبيق من رابط مشاركة (`/p/<id>`).
/// تعمل كحل احتياطي عندما لا يمرّ الرابط عبر onGenerateRoute
/// (مثلاً استراتيجية الروابط Hash على الويب).
Future<void> tryOpenProductFromUrl() async {
  try {
    // الصفحة المستقلة مفتوحة بالفعل (فتحها onGenerateRoute)؟ لا تتدخل.
    if (isProductSharePageOpen) return;

    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    final targetId = extractProductIdFromUri(Uri.base);
    if (targetId == null) return;

    final service = MarketplaceService();
    final item = await service.getProductById(targetId);

    // معرّف متغيّر الحالة (آخر حرف قد يكون كبيراً أو صغيراً)؟ نجرّب الحالة الأخرى.
    MarketplaceItem? found = item;
    if (found == null && targetId.length > 1) {
      final last = targetId.substring(targetId.length - 1);
      if (last == last.toLowerCase() && last == last.toUpperCase()) {
        final alt = targetId.substring(0, targetId.length - 1) + last.toUpperCase();
        found = await service.getProductById(alt);
      }
    }

    if (found == null || !ctx.mounted) return;

    unawaited(Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => ProductSharePage(productId: found!.id),
      ),
    ));
  } catch (_) {}
}

class MusabaqatApp extends StatefulWidget {
  const MusabaqatApp({super.key});

  @override
  State<MusabaqatApp> createState() => _MusabaqatAppState();
}

class _MusabaqatAppState extends State<MusabaqatApp> with WidgetsBindingObserver {
  bool _deeplinkHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _deeplinkHandled) return;
        _deeplinkHandled = true;
        unawaited(tryOpenProductFromUrl());
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'cube3',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      navigatorKey: appNavigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: localeProvider.locale,
      onGenerateRoute: (settings) {
        // صفحة الغرض المستقلة: تفتح مباشرة من رابط المشاركة
        // (https://cube3-dz.pages.dev/p/<id>) دون الدخول إلى التطبيق.
        final uri = Uri.tryParse(settings.name ?? '');
        final segs = uri?.pathSegments ?? const <String>[];
        for (int i = 0; i < segs.length; i++) {
          final s = segs[i].toLowerCase();
          if ((s == 'p' || s == 'product' || s == 'produit') &&
              i + 1 < segs.length) {
            final id = Uri.decodeComponent(segs[i + 1]);
            if (id.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => ProductSharePage(productId: id),
                settings: settings,
              );
            }
          }
        }
        return null;
      },
      home: const SplashScreen(),
    );
  }
}
