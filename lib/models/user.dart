import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  final String name;
  final String? authUserId; // ID del usuario de Firebase Auth que creó este perfil

  User({
    this.id,
    required this.name,
    this.authUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, {String? id}) {
    return User(
      id: id,
      name: map['name'] as String,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] as String,
      authUserId: data['authUserId'] as String?,
    );
  }
}
