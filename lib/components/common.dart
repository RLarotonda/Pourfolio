import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

void notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.local_bar_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.gold),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class DrinkImage extends StatelessWidget {
  const DrinkImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String? url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => url == null || url!.isEmpty
      ? const ColoredBox(
          color: AppTheme.surface,
          child: Center(
            child: Icon(Icons.local_bar, size: 48, color: AppTheme.gold),
          ),
        )
      : Image.network(
          url!,
          fit: fit,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (context, error, stack) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
        );
}

class RatingWidget extends StatelessWidget {
  const RatingWidget({super.key, required this.value, this.onChanged});
  final int value;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    children: List.generate(
      5,
      (i) => onChanged == null
          ? Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.gold,
              size: 19,
            )
          : IconButton(
              tooltip: '${i + 1} estrelas',
              onPressed: () => onChanged!(i + 1),
              icon: Icon(
                i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppTheme.gold,
                size: 32,
              ),
            ),
    ),
  );
}
