import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme.dart';
import '../../domain/recommendation.dart';

/// Glassmorphism-style card used across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: dark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              )
            : null,
        color: dark ? null : Colors.white,
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.08) : Colors.black12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class ChangeText extends StatelessWidget {
  final double? value;
  final double fontSize;
  const ChangeText(this.value, {super.key, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text('—',
          style: TextStyle(fontSize: fontSize, color: AppColors.textSecondary));
    }
    final positive = value! >= 0;
    return Text(
      '${positive ? '+' : ''}${value!.toStringAsFixed(2)}%',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: positive ? AppColors.green : AppColors.red,
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final Rating rating;
  final bool compact;
  const RatingBadge(this.rating, {super.key, this.compact = false});

  Color get _color {
    switch (rating) {
      case Rating.strongBuy:
        return AppColors.green;
      case Rating.buy:
        return const Color(0xFF6EE7B7);
      case Rating.hold:
        return AppColors.yellow;
      case Rating.sell:
        return const Color(0xFFFB923C);
      case Rating.strongSell:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        rating.label,
        style: TextStyle(
          color: _color,
          fontSize: compact ? 10 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  const SkeletonBox({super.key, this.height = 80, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.surface.withOpacity(0.5),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinIcon extends StatelessWidget {
  final String url;
  final String symbol;
  final double size;
  const CoinIcon(
      {super.key, required this.url, required this.symbol, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() => CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.violet.withOpacity(0.3),
        child: Text(
          symbol.isNotEmpty ? symbol[0] : '?',
          style: const TextStyle(
              color: AppColors.cyan, fontWeight: FontWeight.bold),
        ),
      );
}
