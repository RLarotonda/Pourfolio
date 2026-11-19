import 'package:flutter/material.dart';

import '../controllers/library_controller.dart';
import '../model/collection_model.dart';
import '../model/cocktail_model.dart';
import '../components/common.dart';
import '../components/cocktail_grid.dart';
import 'cocktail_page.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key, required this.controller, this.adding});
  final LibraryController controller;
  final Cocktail? adding;
  Future<void> _name(
    BuildContext context, {
    DrinkCollection? collection,
  }) async {
    final text = TextEditingController(text: collection?.name ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(collection == null ? 'Nova coleção' : 'Renomear coleção'),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nome da coleção'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (text.text.trim().isNotEmpty) {
                Navigator.pop(ctx, text.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    // O controller do diálogo é liberado depois que a animação de saída termina.
    Future<void>.delayed(const Duration(milliseconds: 300), text.dispose);
    if (value == null || !context.mounted) {
      return;
    }
    try {
      await controller.saveCollection(current: collection, name: value);
    } catch (e) {
      if (context.mounted) {
        notice(context, 'Não foi possível salvar a coleção.');
      }
    }
  }

  Future<void> _delete(BuildContext context, DrinkCollection collection) async {
    if (!await confirm(
      context,
      'Excluir coleção?',
      'As receitas e experiências do diário serão preservadas.',
    )) {
      return;
    }
    try {
      await controller.save(
        'collections',
        collection.id,
        collection.toMap(),
        delete: true,
      );
    } catch (e) {
      if (context.mounted) {
        notice(context, 'Não foi possível excluir a coleção.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(adding == null ? 'Suas coleções' : 'Escolha uma coleção'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _name(context),
        tooltip: 'Criar coleção',
        child: const Icon(Icons.add),
      ),
      body: controller.collections.isEmpty
          ? const EmptyState(
              'Uma seleção com sua assinatura',
              'Crie uma coleção e adicione receitas pela tela de detalhes.',
              icon: Icons.collections_bookmark_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.collections.length,
              itemBuilder: (context, index) {
                final item = controller.collections[index];
                final included =
                    adding != null && item.drinks.containsKey(adding!.id);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.collections_bookmark_outlined),
                    title: Text(item.name),
                    subtitle: Text('${item.drinks.length} receita(s)'),
                    onTap: () async {
                      if (adding != null) {
                        try {
                          await controller.setCollectionDrink(
                            item,
                            adding!,
                            !included,
                          );
                          if (context.mounted) {
                            notice(
                              context,
                              included
                                  ? 'Receita removida.'
                                  : 'Receita adicionada.',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            notice(
                              context,
                              'Não foi possível alterar a coleção.',
                            );
                          }
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CollectionDetails(
                              controller: controller,
                              id: item.id,
                            ),
                          ),
                        );
                      }
                    },
                    trailing: adding != null
                        ? Icon(
                            included
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                          )
                        : PopupMenuButton<String>(
                            onSelected: (v) => v == 'rename'
                                ? _name(context, collection: item)
                                : _delete(context, item),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Renomear'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
    ),
  );
}

class CollectionDetails extends StatelessWidget {
  const CollectionDetails({
    super.key,
    required this.controller,
    required this.id,
  });
  final LibraryController controller;
  final String id;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final matches = controller.collections.where((c) => c.id == id);
      if (matches.isEmpty) {
        return Scaffold(
          appBar: AppBar(),
          body: const EmptyState(
            'Coleção indisponível',
            'Esta coleção foi excluída ou não está disponível nesta sessão.',
          ),
        );
      }
      final collection = matches.first;
      final drinks = collection.drinks.values.map(Cocktail.fromStored).toList();
      return Scaffold(
        appBar: AppBar(title: Text(collection.name)),
        body: drinks.isEmpty
            ? const EmptyState(
                'Escolha suas receitas',
                'Abra um cocktail em Explorar e toque em adicionar a uma coleção.',
              )
            : CocktailGrid(
                drinks: drinks,
                onTap: (c) => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CocktailPage(c, controller: controller),
                  ),
                ),
                actionIcon: Icons.remove_circle_outline,
                actionTooltip: 'Remover da coleção',
                onFavorite: (c) async {
                  if (!await confirm(context, 'Remover da coleção?', c.name)) {
                    return;
                  }
                  try {
                    await controller.setCollectionDrink(collection, c, false);
                  } catch (e) {
                    if (context.mounted) {
                      notice(context, 'Não foi possível remover a receita.');
                    }
                  }
                },
              ),
      );
    },
  );
}
