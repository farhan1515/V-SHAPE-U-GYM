import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:v_shape_app/models/attendence.dart';

import '../models/customer.dart';
import '../models/plan.dart';
import '../models/notification.dart' as app;
import '../models/revenue_history.dart';
import 'dart:developer' as developer;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Customer operations
  Future<void> addCustomer(Customer customer) async {
    try {
      developer.log('Adding customer: ${customer.toMap()}');
      await _firestore
          .collection('customers')
          .doc(customer.id)
          .set(customer.toMap());

      // Add initial revenue history
      final revenueHistory = RevenueHistory(
        id: Uuid().v4(),
        customerId: customer.id,
        customerName: customer.name,
        amount: customer.fees,
        paymentDate: customer.startDate,
        paymentType: 'new',
        membershipStartDate: customer.startDate,
        membershipEndDate: customer.endDate,
      );
      await addRevenueHistory(revenueHistory);

      developer.log('Customer added successfully');
    } catch (e, stackTrace) {
      developer.log('Error adding customer: $e',
          error: e, stackTrace: stackTrace);
      throw Exception('Failed to add customer: $e');
    }
  }

  Future<void> updateCustomer(Customer customer,
      {bool isRenewal = false}) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customer.id)
          .update(customer.toMap());

      // If this is a renewal, add to revenue history
      if (isRenewal) {
        final revenueHistory = RevenueHistory(
          id: Uuid().v4(),
          customerId: customer.id,
          customerName: customer.name,
          amount: customer.fees,
          paymentDate: customer.startDate,
          paymentType: 'renewal',
          membershipStartDate: customer.startDate,
          membershipEndDate: customer.endDate,
        );
        await addRevenueHistory(revenueHistory);
      }
    } catch (e) {
      developer.log('Error updating customer: $e', error: e);
      throw Exception('Failed to update customer: $e');
    }
  }

  // New method to update customer and reflect fee changes in revenue history
  Future<void> updateCustomerWithRevenueHistory(
      Customer updatedCustomer, double oldFees) async {
    try {
      // Check if fees have changed
      if (updatedCustomer.fees != oldFees) {
        // First, update the customer document
        await _firestore
            .collection('customers')
            .doc(updatedCustomer.id)
            .update(updatedCustomer.toMap());

        // Create a new fee adjustment record
        final revenueHistory = RevenueHistory(
          id: Uuid().v4(),
          customerId: updatedCustomer.id,
          customerName: updatedCustomer.name,
          amount: updatedCustomer.fees -
              oldFees, // The adjustment amount (can be negative)
          paymentDate: DateTime.now(),
          paymentType: 'fee_adjustment',
          membershipStartDate: updatedCustomer.startDate,
          membershipEndDate: updatedCustomer.endDate,
        );

        await addRevenueHistory(revenueHistory);

        // Log the adjustment
        developer.log(
            'Fee adjusted from $oldFees to ${updatedCustomer.fees} for customer ${updatedCustomer.name}');
      } else {
        // If fees haven't changed, just update the customer
        await _firestore
            .collection('customers')
            .doc(updatedCustomer.id)
            .update(updatedCustomer.toMap());
      }
    } catch (e) {
      developer.log('Error updating customer with revenue history: $e',
          error: e);
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _firestore.collection('customers').doc(id).delete();
  }

  Stream<List<Customer>> getCustomers() {
    return _firestore.collection('customers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Customer.fromMap(doc.data())).toList());
  }

  // Plan operations
  Future<void> addPlan(Plan plan) async {
    await _firestore.collection('plans').doc(plan.id).set(plan.toMap());
  }

  Stream<List<Plan>> getPlans() {
    return _firestore.collection('plans').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Plan.fromMap(doc.data())).toList());
  }

  // Attendance operations
  Future<void> addAttendance(Attendance attendance) async {
    await _firestore
        .collection('attendance')
        .doc(attendance.id)
        .set(attendance.toMap());
  }

  Future<bool> hasCheckedInToday(String customerId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final snapshot = await _firestore
        .collection('attendance')
        .where('customerId', isEqualTo: customerId)
        .where('timestamp',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('timestamp', isLessThan: endOfDay.toIso8601String())
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Attendance>> getAttendanceForCustomer(String customerId) {
    return _firestore
        .collection('attendance')
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Attendance.fromMap(doc.data()))
            .toList());
  }

  Future<DateTime?> getLastAttendance(String customerId) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DateTime.parse(snapshot.docs.first.data()['timestamp']);
  }

  // Notification operations
  Future<void> addNotification(app.Notification notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  Stream<List<app.Notification>> getNotifications() {
    return _firestore.collection('notifications').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => app.Notification.fromMap(doc.data()))
            .toList());
  }

  // Birthday check
  Future<List<Customer>> getBirthdayCustomers() async {
    final today = DateTime.now();
    final customers = await _firestore.collection('customers').get();

    return customers.docs
        .map((doc) => Customer.fromMap(doc.data()))
        .where((customer) {
      final dob = customer.dateOfBirth;
      return dob.month == today.month && dob.day == today.day;
    }).toList();
  }

  // In FirebaseService class
  Future<void> updatePlan(Plan plan) async {
    await _firestore.collection('plans').doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String planId) async {
    await _firestore.collection('plans').doc(planId).delete();
  }

  // Updated Revenue operations
  Future<double> getTotalRevenue() async {
    final history = await _firestore.collection('revenue_history').get();
    return history.docs.fold<double>(
        0, (sum, doc) => sum + (doc.data()['amount'] as num).toDouble());
  }

  Future<double> getTodayRevenue() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final history = await _firestore
        .collection('revenue_history')
        .where('paymentDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('paymentDate', isLessThan: endOfDay.toIso8601String())
        .get();

    return history.docs.fold<double>(
        0, (sum, doc) => sum + (doc.data()['amount'] as num).toDouble());
  }

  Future<double> getWeeklyRevenue() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final startOfDay =
        DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    final history = await _firestore
        .collection('revenue_history')
        .where('paymentDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .get();

    return history.docs.fold<double>(
        0, (sum, doc) => sum + (doc.data()['amount'] as num).toDouble());
  }

  Future<Map<String, double>> getMonthlyRevenue() async {
    final history = await _firestore.collection('revenue_history').get();
    Map<String, double> monthlyRevenue = {};
    for (var doc in history.docs) {
      final paymentDate = DateTime.parse(doc.data()['paymentDate']);
      final monthYear = DateFormat('MMMM yyyy').format(paymentDate);
      final amount = (doc.data()['amount'] as num).toDouble();
      monthlyRevenue[monthYear] = (monthlyRevenue[monthYear] ?? 0) + amount;
    }
    // Sort months in descending order
    final sortedMonths = monthlyRevenue.keys.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy')
          .parse(b)
          .compareTo(DateFormat('MMMM yyyy').parse(a)));
    Map<String, double> sortedRevenue = {};
    for (var month in sortedMonths) {
      sortedRevenue[month] = monthlyRevenue[month]!;
    }
    return sortedRevenue;
  }

  Future<List<RevenueHistory>> getRecentTransactions() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    final startOfDay =
        DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);
    final history = await _firestore
        .collection('revenue_history')
        .where('paymentDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .orderBy('paymentDate', descending: true)
        .get();
    return history.docs
        .map((doc) => RevenueHistory.fromMap(doc.data()))
        .toList();
  }

  // New method for handling renewals
  Future<void> renewMembership({
    required Customer updatedCustomer,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required double newFees,
  }) async {
    try {
      // Update all fields of the customer
      await _firestore
          .collection('customers')
          .doc(updatedCustomer.id)
          .update(updatedCustomer.toMap());

      // Create renewal history
      final renewalHistory = RevenueHistory(
        id: Uuid().v4(),
        customerId: updatedCustomer.id,
        customerName: updatedCustomer.name,
        amount: newFees,
        paymentDate: newStartDate,
        paymentType: 'renewal',
        membershipStartDate: newStartDate,
        membershipEndDate: newEndDate,
      );

      // Add renewal history
      await addRevenueHistory(renewalHistory);
    } catch (e) {
      developer.log('Error renewing membership: $e', error: e);
      throw Exception('Failed to renew membership: $e');
    }
  }

  // Revenue History operations
  Future<void> addRevenueHistory(RevenueHistory history) async {
    try {
      await _firestore
          .collection('revenue_history')
          .doc(history.id)
          .set(history.toMap());
    } catch (e) {
      developer.log('Error adding revenue history: $e', error: e);
      throw Exception('Failed to add revenue history: $e');
    }
  }

  Future<List<RevenueHistory>> getCustomerRevenueHistory(
      String customerId) async {
    final history = await _firestore
        .collection('revenue_history')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .get();
    return history.docs
        .map((doc) => RevenueHistory.fromMap(doc.data()))
        .toList();
  }
}
