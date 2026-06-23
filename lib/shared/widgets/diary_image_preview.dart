import 'dart:io';

import 'package:flutter/material.dart';
import 'package:florea/core/constants/app_colors.dart';

/// Заглушка для отсутствующего или повреждённого фото.
class MissingImagePlaceholder extends StatelessWidget {
  const MissingImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray.withValues(alpha: 0.15),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.gray,
      ),
    );
  }
}

/// Превью локального фото дневника с обработкой отсутствующих файлов.
class DiaryImagePreview extends StatelessWidget {
  const DiaryImagePreview({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (!file.existsSync()) {
      return MissingImagePlaceholder(
        width: width,
        height: height,
        borderRadius: radius,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => MissingImagePlaceholder(
          width: width,
          height: height,
          borderRadius: radius,
        ),
      ),
    );
  }
}
