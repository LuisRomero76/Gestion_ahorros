import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/record.dart';

class AppProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;

  List<User> _users = [];
  List<Category> _categories = [];
  List<Record> _records = [];
  double _totalSavings = 0.0;
  Map<String, double> _savingsByCategory = {};
  List<DateTime> _datesWithRecords = [];

  // Getters
  List<User> get users => _users;
  List<Category> get categories => _categories;
  List<Record> get records => _records;
  double get totalSavings => _totalSavings;
  Map<String, double> get savingsByCategory => _savingsByCategory;
  List<DateTime> get datesWithRecords => _datesWithRecords;

  // Obtener el ID del usuario actual autenticado
  String? get currentUserId => _firestore.currentUserId;

  // Cargar datos iniciales
  Future<void> loadInitialData() async {
    await Future.wait([
      loadUsers(),
      loadCategories(),
      loadRecords(),
    ]);
  }

  // Cargar usuarios
  Future<void> loadUsers() async {
    _users = await _firestore.getUsers();
    notifyListeners();
  }

  // Cargar categorías
  Future<void> loadCategories() async {
    _categories = await _firestore.getCategories();
    notifyListeners();
  }

  // Cargar registros
  Future<void> loadRecords() async {
    _records = await _firestore.getRecords();
    await _loadTotals();
    await _loadDatesWithRecords();
    notifyListeners();
  }

  // Cargar totales
  Future<void> _loadTotals() async {
    _totalSavings = await _firestore.getTotalSavings();
    _savingsByCategory = await _firestore.getSavingsByCategory();
  }

  // Cargar fechas con registros
  Future<void> _loadDatesWithRecords() async {
    _datesWithRecords = await _firestore.getDatesWithRecords();
  }

  // Agregar un nuevo registro
  Future<void> addRecord(Record record) async {
    await _firestore.insertRecord(record);
    await loadRecords();
  }

  // Eliminar un registro
  Future<void> deleteRecord(String id) async {
    await _firestore.deleteRecord(id);
    await loadRecords();
  }

  // Filtrar registros por usuario
  Future<void> filterByUser(String userId) async {
    _records = await _firestore.getRecordsByUser(userId);
    notifyListeners();
  }

  // Filtrar registros por categoría
  Future<void> filterByCategory(String categoryId) async {
    _records = await _firestore.getRecordsByCategory(categoryId);
    notifyListeners();
  }

  // Limpiar filtros y mostrar todos
  Future<void> clearFilters() async {
    await loadRecords();
  }

  // Verificar si una fecha tiene registros
  bool hasRecordsOnDate(DateTime date) {
    return _datesWithRecords.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  // Obtener registros de una fecha específica
  Future<List<Record>> getRecordsByDate(DateTime date) async {
    return await _firestore.getRecordsByDate(date);
  }

  // CRUD de Categorías
  Future<void> addCategory(Category category) async {
    await _firestore.addCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(String id, Category category) async {
    await _firestore.updateCategory(id, category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.deleteCategory(id);
    await loadCategories();
    await loadRecords(); // Recargar registros porque algunos pueden haberse eliminado
  }

  // CRUD de Usuarios/Personas
  Future<void> addUser(String name) async {
    await _firestore.createUserProfile(name);
    await loadUsers();
  }

  Future<void> deleteUser(String userId) async {
    // El servicio de Firestore ya maneja la eliminación en cascada
    await _firestore.deleteUserProfile(userId);
    await loadUsers();
    await loadRecords(); // Recargar registros después de eliminar el usuario
  }
}
