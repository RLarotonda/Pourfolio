import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/library_controller.dart';
import '../model/cocktail_model.dart';
import '../service/cocktail_service.dart';
import '../theme/app_theme.dart';
import '../components/common.dart';
import '../components/cocktail_grid.dart';
import 'cocktail_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.controller});
  final LibraryController controller;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _service = CocktailService(), _text = TextEditingController();
  List<Cocktail> _drinks = [];
  bool _ingredient = false, _loading = true, _random = false;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _search(initial: true);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _search({bool initial = false}) async {
    final text = _text.text.trim();
    if (!initial && text.isEmpty) {
      notice(context, 'Digite um nome ou ingrediente.');
      return;
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await (initial
          ? _service.searchByLetter('m')
          : _ingredient
          ? _service.filterByIngredient(text)
          : _service.searchByName(text));
      if (mounted && request == _request) {
        setState(() => _drinks = result);
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(
          () => _error = 'Não foi possível buscar receitas. Verifique a internet e tente novamente.',
        );
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  void _open(Cocktail c) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CocktailPage(c, controller: widget.controller),
    ),
  );
  Future<void> _surprise() async {
    setState(() => _random = true);
    try {
      final c = await _service.getRandom();
      if (mounted) {
        if (c != null) {
          _open(c);
        } else {
          notice(context, 'Nenhum cocktail retornado.');
        }
      }
    } catch (e) {
      if (mounted) {
        notice(context, 'Não foi possível consultar a API. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _random = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => NestedScrollView(
    headerSliverBuilder: (context, innerBoxIsScrolled) => [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'POURFOLIO',
                    style: TextStyle(
                      letterSpacing: 3,
                      fontSize: 12,
                      color: AppTheme.gold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sortear um cocktail',
                    onPressed: _random ? null : _surprise,
                    icon: _random
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.casino_outlined,
                            color: AppTheme.gold,
                          ),
                  ),
                ],
              ),
              Text(
                'Olá, ${(FirebaseAuth.instance.currentUser?.displayName ?? 'explorador').split(' ').first}.',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              const Text(
                'Uma receita.\nUma nova história.',
                style: TextStyle(
                  fontSize: 33,
                  fontFamily: 'PlayfairDisplay',
                  height: 1.12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _text,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: _ingredient
                      ? 'Busque um ingrediente, ex.: lime'
                      : 'Busque seu próximo cocktail',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Pesquisar',
                    onPressed: () => _search(),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Por nome'),
                    selected: !_ingredient,
                    onSelected: (_) => setState(() => _ingredient = false),
                  ),
                  ChoiceChip(
                    label: const Text('Por ingrediente'),
                    selected: _ingredient,
                    onSelected: (_) => setState(() => _ingredient = true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState('Busca indisponível', _error!),
                TextButton(
                  onPressed: () => _search(initial: _text.text.trim().isEmpty),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        : _drinks.isEmpty
        ? const EmptyState(
            'Nenhum cocktail encontrado',
            'Tente outro nome ou um ingrediente em inglês.',
          )
        : CocktailGrid(
            drinks: _drinks,
            onTap: _open,
            isFavorite: widget.controller.isFavorite,
            onFavorite: (c) async {
              try {
                await widget.controller.toggleFavorite(c);
              } catch (e) {
                if (context.mounted) {
                  notice(context, 'Não foi possível salvar o favorito.');
                }
              }
            },
          ),
  );
}
