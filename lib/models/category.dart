import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id;
  final String name;
  final double defaultAmount;

  Category({
    this.id,
    required this.name,
    required this.defaultAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'default_amount': defaultAmount,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'defaultAmount': defaultAmount,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map, {String? id}) {
    return Category(
      id: id,
      name: map['name'] as String,
      defaultAmount: (map['default_amount'] ?? map['defaultAmount']) as double,
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] as String,
      defaultAmount: (data['defaultAmount'] as num).toDouble(),
    );
  }
}
