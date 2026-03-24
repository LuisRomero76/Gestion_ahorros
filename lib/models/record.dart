import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String? id;
  final String userId;
  final String categoryId;
  final DateTime date;
  final double amount;

  // Campos adicionales para mostrar en UI
  String? userName;
  String? categoryName;

  // Campos para rastrear quién agregó el registro
  String? addedBy; // UID del usuario de Firebase Auth que agregó el registro
  String? addedByName; // Nombre del usuario que agregó el registro
  DateTime? addedAt; // Cuándo se agregó el registro

  Record({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.date,
    required this.amount,
    this.userName,
    this.categoryName,
    this.addedBy,
    this.addedByName,
    this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'amount': amount,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'amount': amount,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map, {String? id}) {
    return Record(
      id: id,
      userId: (map['user_id'] ?? map['userId']) as String,
      categoryId: (map['category_id'] ?? map['categoryId']) as String,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      userName: map['user_name'] as String?,
      categoryName: map['category_name'] as String?,
    );
  }

  factory Record.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Record(
      id: doc.id,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      addedBy: data['addedBy'] as String?,
      addedAt: data['addedAt'] != null ? (data['addedAt'] as Timestamp).toDate() : null,
    );
  }
}
