import 'dart:ui';
import 'package:flutter/material.dart';

/// App Bar موحّد بستايل زجاجي (Glassmorphism):
/// خلفية شبه شفافة + ضباب خفيف (Blur) + بدون ظل،
/// نفس الشكل على كل شاشات التطبيق.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.iconTheme,
    this.backgroundColor, // يُتجاهل: الخلفية دائماً زجاجية
    this.elevation = 0, // يُتجاهل: بدون ظل
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final IconThemeData? iconTheme;
  final Color? backgroundColor;
  final double elevation;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // زجاج فاتح في الوضع الفاتح، وزجاج داكن في الوضع الداكن.
    final defaultGlassColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.45);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          bottom: bottom,
          centerTitle: centerTitle,
          automaticallyImplyLeading: automaticallyImplyLeading,
          iconTheme: iconTheme ?? IconThemeData(color: isDark ? Colors.white : Colors.black87),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: backgroundColor ?? defaultGlassColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}
