import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../model/cocktail_model.dart';
import '../model/diary_model.dart';
import '../model/collection_model.dart';
import '../model/pending_operation.dart';
import '../service/database_service.dart';
import '../service/firestore_service.dart';
import '../service/sync_service.dart';
import '../service/image_service.dart';

class LibraryController extends ChangeNotifier with WidgetsBindingObserver {
  LibraryController(this.user) {
    local = DatabaseService(DatabaseHelper(factory: databaseFactory));
    remote = FirestoreService(FirebaseFirestore.instance);
    sync = SyncService(local, remote.apply, user.uid);
    WidgetsBinding.instance.addObserver(this);
  }
  final User user;
  late final DatabaseService local;
  late final FirestoreService remote;
  late final SyncService sync;
  final images = ImageService();
  static const kinds = ['diary', 'favorites', 'collections'];
  final Map<String, Map<String, Map<String, dynamic>>> _cloud = {
    for (final kind in kinds) kind: {},
  };
  // Confirmações aguardando o stream alcançar a versão confirmada: só em memória.
  final Map<String, PendingOperation> _confirmed = {};
  List<PendingOperation> _pending = [];
  Map<String, String> photos = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _timer;
  bool ready = false,
      syncing = false,
      networkAvailable = false,
      _closed = false;
  String? syncError;
  int get pendingCount => _pending.length;
  String _key(String kind, String id) => '$kind/$id';

  Future<void> initialize() async {
    await _loadLocal();
    if (_closed) {
      return;
    }
    final connectivity = Connectivity();
    try {
      final states = await connectivity.checkConnectivity();
      networkAvailable = states.any((s) => s != ConnectivityResult.none);
    } catch (_) {
      networkAvailable = false;
    }
    if (_closed) {
      return;
    }
    for (final kind in kinds) {
      _subscriptions.add(
        remote
            .watch(user.uid, kind)
            .listen(
              (snapshot) {
                if (_closed || snapshot.metadata.hasPendingWrites) {
                  return;
                }
                final data = {for (final d in snapshot.docs) d.id: d.data()};
                _cloud[kind] = data;
                _confirmed.removeWhere((_, op) {
                  if (op.kind != kind) {
                    return false;
                  }
                  if (op.action == 'delete') {
                    return !data.containsKey(op.id);
                  }
                  final m = data[op.id];
                  return m != null &&
                      (m['revision'] == op.revision ||
                          ((m['updatedAt'] as num?)?.toInt() ?? 0) >=
                              op.updatedAt);
                });
                notifyListeners();
              },
              onError: (Object e) {
                if (_closed) {
                  return;
                }
                syncError = _error(e);
                notifyListeners();
              },
            ),
      );
    }
    _subscriptions.add(
      connectivity.onConnectivityChanged.listen((states) {
        if (_closed) {
          return;
        }
        networkAvailable = states.any((s) => s != ConnectivityResult.none);
        notifyListeners();
        if (networkAvailable) {
          unawaited(synchronize());
        }
      }),
    );
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_pending.isNotEmpty && networkAvailable) {
        unawaited(synchronize());
      }
    });
    ready = true;
    notifyListeners();
    if (networkAvailable) {
      unawaited(synchronize());
    }
  }

  Future<void> _loadLocal() async {
    final pending = await local.pending(user.uid);
    final attachments = await local.photos(user.uid);
    if (_closed) {
      return;
    }
    _pending = pending;
    photos = attachments;
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> records(String kind) {
    final data = {..._cloud[kind]!};
    void apply(PendingOperation op) {
      if (op.action == 'delete') {
        data.remove(op.id);
      } else {
        data[op.id] = op.payload;
      }
    }

    for (final op in _confirmed.values.where((op) => op.kind == kind)) {
      apply(op);
    }
    for (final op in _pending.where((op) => op.kind == kind)) {
      apply(op);
    }
    return data;
  }

  List<DiaryEntry> get diary =>
      records('diary').values.map(DiaryEntry.fromMap).toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
  List<Cocktail> get favorites =>
      records('favorites').values.map(Cocktail.fromStored).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  List<DrinkCollection> get collections =>
      records('collections').values.map(DrinkCollection.fromMap).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  bool isFavorite(String id) => records('favorites').containsKey(id);
  bool isPending(String kind, String id) =>
      _pending.any((op) => op.kind == kind && op.id == id);
  Future<void> save(
    String kind,
    String id,
    Map<String, dynamic> data, {
    bool delete = false,
    bool updatePhoto = false,
    String? photo,
  }) async {
    if (_closed || FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('Sessão encerrada. Entre novamente.');
    }
    await local.enqueue(
      user.uid,
      kind,
      id,
      data,
      delete: delete,
      updatePhoto: updatePhoto,
      photo: photo,
    );
    await _loadLocal();
    if (networkAvailable) {
      unawaited(synchronize());
    }
  }

  Future<void> toggleFavorite(Cocktail c) =>
      save('favorites', c.id, c.toStored(), delete: isFavorite(c.id));
  Future<void> saveDiary(DiaryEntry entry, String? photo) async {
    // A associação da fotografia é local e não é exposta como URL remota.
    await save(
      'diary',
      entry.id,
      entry.toMap(),
      updatePhoto: true,
      photo: photo,
    );
  }

  Future<void> deleteDiary(DiaryEntry entry) async {
    await save('diary', entry.id, entry.toMap(), delete: true);
    final path = photos[entry.id];
    await local.setPhoto(user.uid, entry.id, null);
    await images.delete(path);
    await _loadLocal();
  }

  Future<void> saveCollection({
    DrinkCollection? current,
    required String name,
    Map<String, Map<String, dynamic>>? drinks,
  }) {
    final item = DrinkCollection(
      id: current?.id ?? const Uuid().v4(),
      userId: user.uid,
      name: name.trim(),
      drinks: drinks ?? current?.drinks ?? {},
      createdAt: current?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    return save('collections', item.id, item.toMap());
  }

  Future<void> setCollectionDrink(
    DrinkCollection collection,
    Cocktail drink,
    bool add,
  ) {
    final drinks = {...collection.drinks};
    if (add) {
      drinks[drink.id] = drink.toStored();
    } else {
      drinks.remove(drink.id);
    }
    return saveCollection(
      current: collection,
      name: collection.name,
      drinks: drinks,
    );
  }

  Future<void> synchronize() async {
    if (_closed || syncing) {
      return;
    }
    syncing = true;
    syncError = null;
    notifyListeners();
    try {
      await sync.synchronize((op) async {
        if (!_closed) {
          _confirmed[_key(op.kind, op.id)] = op;
        }
      });
    } catch (e) {
      if (!_closed) {
        syncError = _error(e);
      }
    } finally {
      if (!_closed) {
        await _loadLocal();
        syncing = false;
        notifyListeners();
      }
    }
  }

  String _error(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Envio negado. Confira as regras do Firestore e a conta autenticada.';
    }
    return 'Envio não confirmado. As alterações continuam salvas no aparelho.';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(synchronize());
    }
  }

  @override
  void dispose() {
    _closed = true;
    sync.stop();
    _timer?.cancel();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    WidgetsBinding.instance.removeObserver(this);
    // A conexão SQLite é compartilhada pelo sqflite; não fechá-la enquanto
    // houver uma operação de um controlador recém-descartado em andamento.
    super.dispose();
  }
}
