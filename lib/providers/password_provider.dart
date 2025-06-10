import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final passwordProvider = Provider<PasswordService>((ref) {
  return PasswordService();
});

class PasswordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'passwords';

  Future<Map<String, String>> getPasswords() async {
    try {
      final doc =
          await _firestore.collection(_collection).doc('login_passwords').get();
      if (doc.exists) {
        return Map<String, String>.from(doc.data() ?? {});
      }
      // Initialize with default passwords if document doesn't exist
      final defaultPasswords = {
        'owner': 'GYM1234',
        'attendance': 'GYM123',
      };
      await _firestore
          .collection(_collection)
          .doc('login_passwords')
          .set(defaultPasswords);
      return defaultPasswords;
    } catch (e) {
      throw Exception('Failed to get passwords: $e');
    }
  }

  Future<void> updatePassword(String type, String newPassword) async {
    try {
      await _firestore.collection(_collection).doc('login_passwords').update({
        type: newPassword,
      });
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<bool> verifyPassword(String type, String password) async {
    try {
      final passwords = await getPasswords();
      return passwords[type] == password;
    } catch (e) {
      throw Exception('Failed to verify password: $e');
    }
  }
}
