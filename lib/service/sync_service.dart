import '../model/pending_operation.dart';
import 'database_service.dart';

class SyncService {
  SyncService(this.local, this.send, this.uid);
  final DatabaseService local;
  final Future<void> Function(PendingOperation) send;
  final String uid;
  bool _active = true, _again = false;
  Future<void>? _running;
  Future<void> synchronize(Future<void> Function(PendingOperation) confirmed) {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _run(confirmed).whenComplete(() => _running = null);
  }

  Future<void> _run(Future<void> Function(PendingOperation) confirmed) async {
    do {
      _again = false;
      for (final op in await local.pending(uid)) {
        if (!_active) {
          return;
        }
        await send(op); // Em erro: interrompe sem limpar a pendência.
        if (!_active) {
          return;
        }
        await confirmed(
          op,
        ); // Atualiza a memória antes de retirar a versão da fila.
        await local.acknowledge(op);
      }
    } while (_active && _again);
  }

  void stop() {
    _active = false;
  }
}
