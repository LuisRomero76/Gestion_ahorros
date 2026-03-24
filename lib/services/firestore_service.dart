import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/category.dart';
import '../models/record.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init() {
    // Habilitar persistencia offline
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Obtener el ID del usuario actual autenticado
  String? get currentUserId => auth.FirebaseAuth.instance.currentUser?.uid;

  // ==================== CRUD USERS ====================

  // Crear el perfil del usuario actual con su nombre
  Future<String> createUserProfile(String name) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Crear perfil global en lugar de subcollection
    final docRef = await _firestore.collection('profiles').add({
      'name': name,
      'authUserId': currentUserId, // Guardar referencia al usuario de auth
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Verificar si el usuario ya tiene un perfil creado
  Future<bool> hasUserProfile() async {
    if (currentUserId == null) return false;

    final snapshot = await _firestore
        .collection('profiles')
        .where('authUserId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Obtener el nombre del usuario actual (el primer perfil)
  Future<String?> getCurrentUserName() async {
    if (currentUserId == null) return null;

    final snapshot = await _firestore
        .collection('profiles')
        .where('authUserId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['name'] as String?;
  }

  // Eliminar un perfil de usuario (solo los propios)
  Future<void> deleteUserProfile(String profileId) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Verificar que el perfil pertenece al usuario actual
    final doc = await _firestore.collection('profiles').doc(profileId).get();
    if (!doc.exists || doc.data()!['authUserId'] != currentUserId) {
      throw Exception('No tienes permisos para eliminar este perfil');
    }

    await _firestore.collection('profiles').doc(profileId).delete();
  }

  Future<List<User>> getUsers() async {
    // Ahora todos ven todos los usuarios (sistema compartido)
    final snapshot = await _firestore
        .collection('profiles')
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  Future<User?> getUserById(String id) async {
    final doc = await _firestore.collection('profiles').doc(id).get();

    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }

  // ==================== CRUD CATEGORIES ====================

  Future<List<Category>> getCategories() async {
    // Categorías globales para todos los usuarios
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Stream<List<Category>> getCategoriesStream() {
    return _firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  Future<Category?> getCategoryById(String id) async {
    final doc = await _firestore.collection('categories').doc(id).get();

    if (doc.exists) {
      return Category.fromFirestore(doc);
    }
    return null;
  }

  Future<String> addCategory(Category category) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Agregar información del creador
    final categoryData = category.toFirestore();
    categoryData['createdBy'] = currentUserId;
    categoryData['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('categories').add(categoryData);

    return docRef.id;
  }

  Future<void> updateCategory(String id, Category category) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Agregar información de última modificación
    final categoryData = category.toFirestore();
    categoryData['lastModifiedBy'] = currentUserId;
    categoryData['lastModifiedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('categories').doc(id).update(categoryData);
  }

  Future<void> deleteCategory(String id) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Eliminar todos los registros asociados a esta categoría
    final recordsSnapshot = await _firestore
        .collection('records')
        .where('categoryId', isEqualTo: id)
        .get();

    final batch = _firestore.batch();
    for (var doc in recordsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Eliminar la categoría
    batch.delete(_firestore.collection('categories').doc(id));

    await batch.commit();
  }

  // ==================== CRUD RECORDS ====================

  Future<String> insertRecord(Record record) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    // Agregar información del usuario que crea el registro
    final recordData = record.toFirestore();
    recordData['addedBy'] = currentUserId; // Usuario de Firebase Auth que lo agregó
    recordData['addedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('records').add(recordData);

    return docRef.id;
  }

  Future<List<Record>> getRecords() async {
    // Todos ven todos los registros (sistema compartido)
    final snapshot = await _firestore
        .collection('records')
        .orderBy('date', descending: true)
        .get();

    return await _enrichRecords(snapshot.docs);
  }

  Stream<List<Record>> getRecordsStream() {
    return _firestore
        .collection('records')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) => _enrichRecords(snapshot.docs));
  }

  Future<List<Record>> getRecordsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('records')
        .where('userId', isEqualTo: userId)
        .get();

    final records = await _enrichRecords(snapshot.docs);
    // Ordenar en el cliente para evitar necesidad de índices compuestos
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<List<Record>> getRecordsByCategory(String categoryId) async {
    final snapshot = await _firestore
        .collection('records')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final records = await _enrichRecords(snapshot.docs);
    // Ordenar en el cliente para evitar necesidad de índices compuestos
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<List<Record>> getRecordsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('records')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return await _enrichRecords(snapshot.docs);
  }

  Future<List<DateTime>> getDatesWithRecords() async {
    final snapshot = await _firestore
        .collection('records')
        .orderBy('date')
        .get();

    final dates = snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['date'] as Timestamp;
      final date = timestamp.toDate();
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    return dates.toList();
  }

  Future<double> getTotalSavings() async {
    final snapshot = await _firestore.collection('records').get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }

  Future<Map<String, double>> getSavingsByCategory() async {
    final recordsSnapshot = await _firestore.collection('records').get();
    final categoriesSnapshot = await _firestore.collection('categories').get();

    final categoryMap = {
      for (var doc in categoriesSnapshot.docs)
        doc.id: doc.data()['name'] as String
    };

    final Map<String, double> result = {};

    for (var doc in recordsSnapshot.docs) {
      final data = doc.data();
      final categoryId = data['categoryId'] as String;
      final amount = (data['amount'] as num).toDouble();
      final categoryName = categoryMap[categoryId] ?? 'Desconocido';

      result[categoryName] = (result[categoryName] ?? 0.0) + amount;
    }

    return result;
  }

  Future<void> deleteRecord(String id) async {
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    await _firestore.collection('records').doc(id).delete();
  }

  // ==================== HELPERS ====================

  Future<List<Record>> _enrichRecords(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return [];

    final users = await getUsers();
    final categories = await getCategories();

    final userMap = {for (var user in users) user.id!: user.name};
    final categoryMap = {for (var cat in categories) cat.id!: cat.name};

    // Obtener información de quién agregó cada registro
    final addedByIds = docs
        .map((doc) => doc.data()['addedBy'] as String?)
        .where((id) => id != null)
        .toSet();

    final addedByMap = <String, String>{};
    for (final authUserId in addedByIds) {
      final name = await getAddedByUserName(authUserId!);
      if (name != null) {
        addedByMap[authUserId] = name;
      }
    }

    return docs.map((doc) {
      final record = Record.fromFirestore(doc);
      record.userName = userMap[record.userId];
      record.categoryName = categoryMap[record.categoryId];

      // Enriquecer información de quién agregó el registro
      if (record.addedBy != null) {
        record.addedByName = addedByMap[record.addedBy!] ?? 'Usuario desconocido';
      }

      return record;
    }).toList();
  }

  // Obtener información sobre quién agregó un registro (basado en Firebase Auth UID)
  Future<String?> getAddedByUserName(String authUserId) async {
    final snapshot = await _firestore
        .collection('profiles')
        .where('authUserId', isEqualTo: authUserId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['name'] as String?;
  }
}
