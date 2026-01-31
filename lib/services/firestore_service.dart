import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveCounter(int counter) async {
    await _db.collection('counter_data').add({
      'counter': counter,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
