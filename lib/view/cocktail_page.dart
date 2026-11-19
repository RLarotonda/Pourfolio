import 'package:flutter/material.dart';

import '../model/cocktail_model.dart';
import '../controllers/library_controller.dart';
import '../service/cocktail_service.dart';
import '../theme/app_theme.dart';
import '../components/common.dart';
import 'diary_form_page.dart';
import 'collections_page.dart';

class CocktailPage extends StatefulWidget {
  const CocktailPage(this.cocktail, {super.key, required this.controller});
  final Cocktail cocktail;
  final LibraryController controller;
  @override
  State<CocktailPage> createState() => _CocktailPageState();
}

class _CocktailPageState extends State<CocktailPage> {
  late Cocktail _cocktail;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _cocktail = widget.cocktail;
    if (!_cocktail.isComplete) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final full = await CocktailService().getById(_cocktail.id);
      if (!mounted) {
        return;
      }
      setState(() {
        if (full != null) {
          _cocktail = full;
        } else {
          _error = 'Receita não encontrada.';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              'Conecte-se à internet para carregar a receita completa.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _favorite() async {
    try {
      await widget.controller.toggleFavorite(_cocktail);
    } catch (e) {
      if (mounted) {
        notice(context, 'Não foi possível gravar o favorito.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('A receita'),
        actions: [
          IconButton(
            tooltip: 'Favoritar ou remover favorito',
            onPressed: _favorite,
            icon: Icon(
              widget.controller.isFavorite(_cocktail.id)
                  ? Icons.favorite
                  : Icons.favorite_outline,
              color: AppTheme.gold,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1.15, child: DrinkImage(_cocktail.thumb)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cocktail.name,
                    style: const TextStyle(
                      fontSize: 34,
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_cocktail.category != null)
                        Chip(label: Text(_cocktail.category!)),
                      if (_cocktail.alcoholic != null)
                        Chip(label: Text(_cocktail.alcoholic!)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DiaryFormPage(
                          controller: widget.controller,
                          cocktail: _cocktail,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Registrar experiência'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CollectionsPage(
                          controller: widget.controller,
                          adding: _cocktail,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Adicionar a uma coleção'),
                  ),
                  const SizedBox(height: 28),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null) ...[
                    Text(_error!),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Tentar novamente'),
                    ),
                  ] else ...[
                    _heading('O copo'),
                    Text(_cocktail.glass ?? 'Não informado'),
                    _heading('Ingredientes'),
                    if (_cocktail.ingredients.isEmpty)
                      const Text('Não informados.'),
                    ..._cocktail.ingredients.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•  ',
                              style: TextStyle(color: AppTheme.gold),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _heading('Modo de preparo'),
                    Text(
                      _cocktail.instructions ?? 'Não informado.',
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Receita e fotografia: TheCocktailDB',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 21, color: AppTheme.gold),
    ),
  );
}
