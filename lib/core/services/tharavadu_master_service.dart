import 'package:cloud_firestore/cloud_firestore.dart';

class TharavaduMasterService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('tharavadu_master');

  // റിയൽ-ടൈം സ്ട്രീം: ഭാവിയിലെ എല്ലാ ഡ്രോപ്പ്ഡൗണുകളും ഇത് മാത്രമേ വിളിക്കാൻ പാടുള്ളൂ
  static Stream<List<String>> get liveTharavaduListStream {
    return _collection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String rawName = data['name'] ?? '';
        // ബ്രാക്കറ്റിലുള്ള (പന്തി), (ബന്ധു) തുടങ്ങിയ എന്തെങ്കിലും ഉണ്ടെങ്കിൽ പൂർണ്ണമായി ഒഴിവാക്കി പ്യുവർ പേര് മാത്രം നൽകുന്നു
        return rawName.replaceAll(RegExp(r'\s*\((പന്തി|ബന്ധു)\)'), '').trim();
      }).where((name) => name.isNotEmpty).toList();
    });
  }

  // റിയൽ-ടൈം ഡോക്യുമെന്റുകൾ ഉൾപ്പെടെയുള്ള സ്ട്രീം (അഡ്മിൻ മാനേജ്‌മെന്റിനായി docId സഹിതം)
  static Stream<QuerySnapshot> get liveTharavaduDocsStream {
    return _collection.orderBy('name').snapshots();
  }

  // അഡ്മിൻ പുതിയ തറവാട് ചേർക്കുമ്പോൾ
  static Future<void> addTharavadu(String name) async {
    final cleanName =
        name.replaceAll(RegExp(r'\s*\((പന്തി|ബന്ധു)\)'), '').trim();
    if (cleanName.isEmpty) return;
    await _collection.add({
      'name': cleanName,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // അഡ്മിൻ പേര് തിരുത്തുമ്പോൾ (Edit / Update)
  static Future<void> updateTharavadu(String docId, String newName) async {
    final cleanName =
        newName.replaceAll(RegExp(r'\s*\((പന്തി|ബന്ധു)\)'), '').trim();
    if (cleanName.isEmpty) return;
    await _collection.doc(docId).update({
      'name': cleanName,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // അഡ്മിൻ ഡിലീറ്റ് ചെയ്യുമ്പോൾ
  static Future<void> deleteTharavadu(String docId) async {
    await _collection.doc(docId).delete();
  }
}
