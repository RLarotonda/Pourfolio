import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/pending_operation.dart';

class FirestoreService {
  FirestoreService(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> collection(
    String uid,
    String kind,
  ) => firestore.collection('users').doc(uid).collection(kind);
  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String uid, String kind) =>
      collection(uid, kind).snapshots(includeMetadataChanges: true);
  Future<void> apply(PendingOperation op) async {
    final ref = collection(op.userId, op.kind).doc(op.id);
    // Transações precisam de confirmação do servidor; não são confirmações locais.
    await firestore.runTransaction(
      (tx) async {
        await tx.get(ref); // leitura no servidor torna a operação transacional
        if (op.action == 'delete') {
          tx.delete(ref);
        } else {
          tx.set(ref, {...op.payload, 'synced': true});
        }
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 2,
    );
  }
}
