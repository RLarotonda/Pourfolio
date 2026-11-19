import 'package:flutter/material.dart';

import '../controllers/library_controller.dart';
import '../components/common.dart';
import '../components/cocktail_grid.dart';
import 'cocktail_page.dart';
import 'collections_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, required this.controller});
  final LibraryController controller;
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final drinks = widget.controller.favorites
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Sua seleção',
                  style: TextStyle(
                    fontSize: 30,
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CollectionsPage(controller: widget.controller),
                  ),
                ),
                icon: const Icon(Icons.collections_bookmark_outlined),
                label: const Text('Coleções'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Pesquisar favoritos',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: drinks.isEmpty
              ? const EmptyState(
                  'Guarde o que combina com você',
                  'Toque no coração de uma receita para encontrá-la aqui. Novas consultas à nuvem precisam de internet.',
                  icon: Icons.favorite_outline,
                )
              : CocktailGrid(
                  drinks: drinks,
                  onTap: (c) => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CocktailPage(c, controller: widget.controller),
                    ),
                  ),
                  isFavorite: widget.controller.isFavorite,
                  onFavorite: (c) async {
                    try {
                      await widget.controller.toggleFavorite(c);
                    } catch (e) {
                      if (context.mounted) {
                        notice(context, 'Não foi possível alterar o favorito.');
                      }
                    }
                  },
                ),
        ),
      ],
    );
  }
}
