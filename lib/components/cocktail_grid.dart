import 'package:flutter/material.dart';

import '../model/cocktail_model.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class CocktailGrid extends StatelessWidget {
  const CocktailGrid({
    super.key,
    required this.drinks,
    required this.onTap,
    this.onFavorite,
    this.isFavorite,
    this.actionIcon,
    this.actionTooltip,
  });
  final List<Cocktail> drinks;
  final ValueChanged<Cocktail> onTap;
  final ValueChanged<Cocktail>? onFavorite;
  final bool Function(String)? isFavorite;
  final IconData? actionIcon;
  final String? actionTooltip;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.maxWidth > 650 ? 3 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        mainAxisExtent: 250,
      ),
      itemCount: drinks.length,
      itemBuilder: (context, index) {
        final c = drinks[index];
        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(c),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DrinkImage(c.thumb),
                      if (onFavorite != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filledTonal(
                            tooltip:
                                actionTooltip ??
                                'Favoritar ou remover favorito',
                            onPressed: () => onFavorite!(c),
                            icon: Icon(
                              actionIcon ??
                                  (isFavorite?.call(c.id) == true
                                      ? Icons.favorite
                                      : Icons.favorite_outline),
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    c.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
