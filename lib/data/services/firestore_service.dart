import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translate_app/core/errors/app_exception.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add(data);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Failed to add document', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }

  Future<void> setDocument(
    String documentPath,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.doc(documentPath).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Failed to save document', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }

  Future<Map<String, dynamic>?> getDocument(String documentPath) async {
    try {
      final docSnapshot = await _firestore.doc(documentPath).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['remoteId'] = docSnapshot.id;
        return data;
      }
      return null;
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Failed to get document', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getCollection(
    String collectionPath,
  ) async {
    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['remoteId'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Failed to get collection', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }

  Future<void> deleteDocument(String documentPath) async {
    try {
      await _firestore.doc(documentPath).delete();
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Failed to delete document', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }

  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    const batchLimit = 500;
    try {
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
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Batch write failed', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }

  Future<void> setDocumentWithId(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw FirebaseDataException('Failed to save document', details: e.message);
    } catch (e) {
      throw GeneralException('Unexpected error occurred', details: e.toString());
    }
  }
}
