import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
//  Shared Glass Widgets — Liquid Crystal Design System
// ═══════════════════════════════════════════════════════════

// ─── GlassContainer ──────────────────────────────────────
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = 20,
    this.border = true,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final bool border;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<LiquidThemeExtension>();
    final effectiveBlur = ext?.isPerformanceMode == true ? 0.0 : blur;

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (ext?.glassColor ?? AppColors.glassDark)
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border
                ? Border.all(
                    color: ext?.glassBorderColor ?? AppColors.glassBorder,
                    width: 0.8,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(margin: margin, child: glass),
      );
    }
    return Container(margin: margin, child: glass);
  }
}

// ─── GlassButton ─────────────────────────────────────────
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.width,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final bool isLoading;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: GlassContainer(
          width: widget.width,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          gradient:
              widget.gradient ??
              const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          border: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GlassNavBar ─────────────────────────────────────────
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library,
      label: 'Gallery',
    ),
    _NavItem(
      icon: Icons.wifi_tethering_outlined,
      activeIcon: Icons.wifi_tethering,
      label: 'Share',
    ),
    _NavItem(icon: Icons.lock_outline, activeIcon: Icons.lock, label: 'Vault'),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: GlassContainer(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = selectedIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: selected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.heroGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected ? Colors.white : AppColors.textMuted,
                      size: 22,
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ─── GradientText ────────────────────────────────────────
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.headlineLarge;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style ?? defaultStyle, textAlign: textAlign),
    );
  }
}

// ─── AnimatedGradientBackground ──────────────────────────
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Alignment> _topLeft;
  late Animation<Alignment> _bottomRight;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _topLeft = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _bottomRight = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.bottomRight),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _topLeft.value,
            end: _bottomRight.value,
            colors: const [
              Color(0xFF0A0A14),
              Color(0xFF12082A),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─── Empty State ─────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(colors: AppColors.heroGradient),
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
