import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../controllers/library_controller.dart';
import '../model/diary_model.dart';
import '../model/cocktail_model.dart';
import '../service/cocktail_service.dart';
import '../service/location_service.dart';
import '../components/common.dart';
import '../theme/app_theme.dart';

class DiaryFormPage extends StatefulWidget {
  const DiaryFormPage({
    super.key,
    required this.controller,
    this.cocktail,
    this.entry,
    this.date,
  });
  final LibraryController controller;
  final Cocktail? cocktail;
  final DiaryEntry? entry;
  final DateTime? date;
  @override
  State<DiaryFormPage> createState() => _DiaryFormPageState();
}

class _DiaryFormPageState extends State<DiaryFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _comment;
  late final String _id;
  late DateTime _date;
  Cocktail? _cocktail;
  String? _photo, _originalPhoto;
  double? _lat, _lng;
  int _rating = 0;
  bool _busy = false, _gps = false, _picking = false, _saved = false;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _id = e?.id ?? const Uuid().v4();
    _cocktail = widget.cocktail ?? e?.cocktail;
    _name = TextEditingController(text: e?.name ?? _cocktail?.name ?? '');
    _comment = TextEditingController(text: e?.comment ?? '');
    _date = e?.eventDate ?? widget.date ?? DateTime.now();
    _rating = e?.rating ?? 0;
    _lat = e?.latitude;
    _lng = e?.longitude;
    _originalPhoto = e == null ? null : widget.controller.photos[e.id];
    _photo = _originalPhoto;
  }

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    if (!_saved && _photo != _originalPhoto) {
      unawaited(widget.controller.images.delete(_photo));
    }
    super.dispose();
  }

  Future<void> _image() async {
    setState(() => _picking = true);
    try {
      final path = await widget.controller.images.choose(
        widget.controller.user.uid,
      );
      if (!mounted) {
        await widget.controller.images.delete(path);
        return;
      }
      if (path != null) {
        if (_photo != _originalPhoto) {
          await widget.controller.images.delete(_photo);
        }
        if (mounted) {
          setState(() => _photo = path);
        }
      }
    } catch (e) {
      if (mounted) {
        notice(context, 'Não foi possível selecionar a foto. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _location() async {
    final accepted = await confirm(
      context,
      'Adicionar sua localização?',
      'O GPS será usado para guardar as coordenadas desta experiência na sua conta. A localização é opcional.',
    );
    if (!accepted || !mounted) {
      return;
    }
    setState(() => _gps = true);
    try {
      final position = await LocationService().current();
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        notice(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _gps = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    if (_rating < 1) {
      notice(context, 'Escolha uma avaliação de 1 a 5 estrelas.');
      return;
    }
    setState(() => _busy = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = DiaryEntry(
        id: _id,
        userId: widget.controller.user.uid,
        cocktailId: _cocktail?.id ?? '',
        name: _name.text.trim(),
        imageUrl: _cocktail?.thumb,
        eventDate: _date,
        rating: _rating,
        comment: _comment.text.trim(),
        latitude: _lat,
        longitude: _lng,
        createdAt: widget.entry?.createdAt ?? now,
        updatedAt: now,
      );
      await widget.controller.saveDiary(entry, _photo);
      _saved = true;
      if (_originalPhoto != null && _originalPhoto != _photo) {
        await widget.controller.images.delete(_originalPhoto);
      }
      if (mounted) {
        notice(
          context,
          'Experiência salva. O envio será confirmado quando houver conexão.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        notice(
          context,
          'Não foi possível salvar no aparelho. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickCocktail() async {
    final cocktail = await Navigator.push<Cocktail>(
      context,
      MaterialPageRoute(builder: (_) => const CocktailPicker()),
    );
    if (cocktail != null && mounted) {
      setState(() {
        _cocktail = cocktail;
        _name.text = cocktail.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'Nova experiência' : 'Editar experiência',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'O que ficou na memória?',
                style: TextStyle(
                  fontSize: 29,
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uma receita, sua nota e os detalhes do momento.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickCocktail,
                icon: const Icon(Icons.search),
                label: Text(
                  _cocktail == null
                      ? 'Associar receita da TheCocktailDB'
                      : 'Trocar receita associada',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nome do drink *',
                  prefixIcon: Icon(Icons.local_bar_outlined),
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Informe o nome do drink.'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Data da experiência'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _busy
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (date != null && mounted) {
                          setState(() => _date = date);
                        }
                      },
              ),
              const SizedBox(height: 16),
              const Text(
                'Sua avaliação *',
                style: TextStyle(color: AppTheme.gold),
              ),
              RatingWidget(
                value: _rating,
                onChanged: _busy ? null : (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comment,
                enabled: !_busy,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Seu comentário',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              if (_photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(_photo!),
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => const SizedBox(
                      height: 100,
                      child: Center(child: Text('Imagem indisponível')),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final old = _photo;
                          setState(() => _photo = null);
                          if (old != _originalPhoto) {
                            await widget.controller.images.delete(old);
                          }
                        },
                  icon: const Icon(Icons.close),
                  label: const Text('Remover foto'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _busy || _picking ? null : _image,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _picking
                      ? 'Abrindo galeria…'
                      : _photo == null
                      ? 'Adicionar foto pessoal'
                      : 'Trocar foto pessoal',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Opcional. A foto fica neste aparelho; a imagem original da receita é preservada.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              if (_lat != null && _lng != null) ...[
                Text(
                  '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                  style: const TextStyle(color: AppTheme.gold),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _lat = null;
                          _lng = null;
                        }),
                  child: const Text('Remover localização'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _busy || _gps ? null : _location,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _gps ? 'Obtendo posição…' : 'Usar minha localização',
                ),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _busy || _gps || _picking ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_busy ? 'Salvando…' : 'Salvar experiência'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CocktailPicker extends StatefulWidget {
  const CocktailPicker({super.key});
  @override
  State<CocktailPicker> createState() => _CocktailPickerState();
}

class _CocktailPickerState extends State<CocktailPicker> {
  final _query = TextEditingController();
  final _service = CocktailService();
  List<Cocktail> _items = [];
  bool _busy = false;
  String _message =
      'Pesquise uma receita por nome. A consulta precisa de internet.';
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final list = await _service.searchByName(_query.text);
      if (mounted) {
        setState(() {
          _items = list;
          _message = 'Nenhuma receita encontrada.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = [];
          _message = 'Busca indisponível. Você pode voltar e informar o nome manualmente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Associar uma receita')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _query,
            onSubmitted: (_) => _search(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Nome do cocktail',
              suffixIcon: IconButton(
                onPressed: _busy ? null : _search,
                tooltip: 'Pesquisar',
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
        Expanded(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? EmptyState('Encontre sua receita', _message)
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: DrinkImage(c.thumb),
                        ),
                      ),
                      title: Text(c.name),
                      subtitle: Text(c.category ?? ''),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
