import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/library_controller.dart';
import '../model/diary_model.dart';
import '../components/common.dart';
import '../theme/app_theme.dart';
import 'diary_form_page.dart';
import 'cocktail_page.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key, required this.controller});
  final LibraryController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Seu diário')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DiaryFormPage(controller: controller),
        ),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Registrar'),
    ),
    body: controller.diary.isEmpty
        ? const EmptyState(
            'Experiências que merecem ficar',
            'Registre o que você preparou ou experimentou. Suas novas anotações também podem ser feitas sem internet.',
            icon: Icons.menu_book_outlined,
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              for (final entry in controller.diary)
                DiaryTile(entry: entry, controller: controller),
            ],
          ),
  );
}

class DiaryTile extends StatelessWidget {
  const DiaryTile({super.key, required this.entry, required this.controller});
  final DiaryEntry entry;
  final LibraryController controller;
  @override
  Widget build(BuildContext context) {
    final photo = controller.photos[entry.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  DiaryDetails(controller: controller, id: entry.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 78,
                    height: 92,
                    child: photo != null
                        ? Image.file(
                            File(photo),
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) =>
                                DrinkImage(entry.imageUrl),
                          )
                        : DrinkImage(entry.imageUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          "dd MMM yyyy",
                          'pt_BR',
                        ).format(entry.eventDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.gold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RatingWidget(value: entry.rating),
                      if (entry.comment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            entry.comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                    ],
                  ),
                ),
                if (controller.isPending('diary', entry.id))
                  const Tooltip(
                    message: 'Aguardando envio',
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 17,
                      color: AppTheme.gold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DiaryDetails extends StatelessWidget {
  const DiaryDetails({super.key, required this.controller, required this.id});
  final LibraryController controller;
  final String id;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final items = controller.diary.where((e) => e.id == id);
      if (items.isEmpty) {
        return Scaffold(
          appBar: AppBar(),
          body: const EmptyState(
            'Registro indisponível',
            'O registro foi excluído ou não está disponível nesta sessão.',
          ),
        );
      }
      final entry = items.first, photo = controller.photos[id];
      return Scaffold(
        appBar: AppBar(
          title: const Text('Uma boa história'),
          actions: [
            IconButton(
              tooltip: 'Editar registro',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DiaryFormPage(controller: controller, entry: entry),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir registro',
              onPressed: () async {
                if (!await confirm(
                  context,
                  'Excluir experiência?',
                  'A exclusão também será enviada à nuvem quando houver conexão.',
                )) {
                  return;
                }
                try {
                  await controller.deleteDiary(entry);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    notice(
                      context,
                      'Não foi possível excluir. Tente novamente.',
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: ListView(
          children: [
            if (photo != null)
              AspectRatio(
                aspectRatio: 1.15,
                child: Image.file(
                  File(photo),
                  fit: BoxFit.cover,
                  errorBuilder: (context, e, s) => DrinkImage(entry.imageUrl),
                ),
              )
            else
              AspectRatio(aspectRatio: 1.4, child: DrinkImage(entry.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  RatingWidget(value: entry.rating),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat(
                      "dd 'de' MMMM 'de' yyyy",
                      'pt_BR',
                    ).format(entry.eventDate),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    entry.comment.isEmpty ? 'Sem comentário.' : entry.comment,
                    style: const TextStyle(fontSize: 17, height: 1.6),
                  ),
                  if (entry.latitude != null && entry.longitude != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'LOCAL DA EXPERIÊNCIA',
                      style: TextStyle(
                        color: AppTheme.gold,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      '${entry.latitude!.toStringAsFixed(6)}, ${entry.longitude!.toStringAsFixed(6)}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    controller.isPending('diary', id)
                        ? 'Salvo no aparelho • envio pendente'
                        : 'Confirmado na nuvem',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  if (photo != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Foto pessoal disponível somente neste aparelho.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  if (entry.cocktailId.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => CocktailPage(
                            entry.cocktail,
                            controller: controller,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.local_bar_outlined),
                      label: const Text('Consultar receita'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
