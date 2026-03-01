import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Belirli bir koleksiyona yeni veri ekler (ID otomatik oluşturulur)
  Future<String> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    final docRef = await _firestore.collection(collectionPath).add(data);
    return docRef.id;
  }

  // Belirli bir ID ile belge kaydeder veya günceller
  Future<void> setDocument(
    String documentPath,
    Map<String, dynamic> data,
  ) async {
    await _firestore.doc(documentPath).set(data, SetOptions(merge: true));
  }

  // Belirli bir belgeyi getirir
  Future<Map<String, dynamic>?> getDocument(String documentPath) async {
    final docSnapshot = await _firestore.doc(documentPath).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['remoteId'] = docSnapshot.id;
      return data;
    }
    return null;
  }

  // Bir koleksiyondaki tüm belgeleri getirir
  Future<List<Map<String, dynamic>>> getCollection(
    String collectionPath,
  ) async {
    final querySnapshot = await _firestore.collection(collectionPath).get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['remoteId'] = doc.id;
      return data;
    }).toList();
  }

  // Belirli bir belgeyi siler
  Future<void> deleteDocument(String documentPath) async {
    await _firestore.doc(documentPath).delete();
  }

  // Batch write: toplu yazma işlemi
  // Her bir entry: {'path': 'col/doc', 'data': {...}, 'type': 'set' | 'delete'}
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    // Firebase batch limit: 500 per batch
    const batchLimit = 500;
    for (var i = 0; i < operations.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = operations.skip(i).take(batchLimit);

      for (final op in chunk) {
        final docRef = _firestore.doc(op['path'] as String);
        final type = op['type'] as String;

        if (type == 'set') {
          batch.set(
            docRef,
            op['data'] as Map<String, dynamic>,
            SetOptions(merge: true),
          );
        } else if (type == 'delete') {
          batch.delete(docRef);
        }
      }

      await batch.commit();
    }
  }

  // Belirli bir koleksiyona belirli bir ID ile belge ekler
  Future<void> setDocumentWithId(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(collectionPath)
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }
}
