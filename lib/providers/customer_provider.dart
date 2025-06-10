import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(firebaseServiceProvider).getCustomers();
});