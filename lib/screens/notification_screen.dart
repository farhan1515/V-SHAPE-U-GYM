import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart' as app;
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/notification_provider.dart';

import '../widgets/shimmer_loading.dart';

class ActivityFeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ Color(0xFF2C3E50),
              Color(0xFF1A1A2E), ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: customersAsync.when(
                    data: (customers) => notificationsAsync.when(
                      data: (notifications) => _buildNotificationList(
                          context, ref, notifications, customers),
                      loading: () => ShimmerLoading(),
                      error: (error, stack) => Center(
                        child: Text(
                          'Error: $error',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                    loading: () => ShimmerLoading(),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error: $error',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ Color(0xFF8E2DE2),
            Color(0xFF4A00E0),],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Activity Feed',
          style: GoogleFonts.anton(
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, WidgetRef ref,
      List<app.Notification> notifications, List<Customer> customers) {
    final firebaseService = ref.read(firebaseServiceProvider);
    final today = DateTime.now();

    // Only add birthday notifications
    List<Widget> notificationWidgets = [];

    // Add birthday notifications
    notificationWidgets.add(
      FutureBuilder<List<Customer>>(
        future: firebaseService.getBirthdayCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox.shrink();
          }

          final birthdayCustomers = snapshot.data ?? [];
          if (birthdayCustomers.isEmpty) {
            return SizedBox.shrink();
          }

          return Column(
            children: birthdayCustomers
                .map((customer) => _buildNotificationCard(
                      message: '🎂 Happy Birthday ${customer.name}! 🎉',
                      createdAt: today,
                      isBirthday: true,
                    ))
                .toList(),
          );
        },
      ),
    );

    // Remove absence notifications
    for (final customer in customers) {
      notificationWidgets.add(
        FutureBuilder<DateTime?>(
          future: firebaseService.getLastAttendance(customer.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            }
    
            final lastAttendance = snapshot.data;
            final daysSinceLast = lastAttendance == null
                ? 3
                : today.difference(lastAttendance).inDays;
    
            if (daysSinceLast >= 3) {
              return _buildNotificationCard(
                message:
                    '⚠️ ${customer.name} has not visited the gym for the last 3 days.',
                createdAt: today,
              );
            }
            return SizedBox.shrink();
          },
        ),
      );
    }

    // Add stored notifications
    notificationWidgets.addAll(
      notifications.map((notification) => _buildNotificationCard(
            message: notification.message,
            createdAt: notification.createdAt,
          )),
    );

    if (notificationWidgets.isEmpty) {
      return Center(
        child: Text(
          'No notifications',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView(
      children: notificationWidgets,
    );
  }

  Widget _buildNotificationCard({
    required String message,
    required DateTime createdAt,
    bool isBirthday = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBirthday
              ? [
                  Color(0xFFFFB81C),
                  Color(0xFFF29100),
                ]
              : [
                  Color(0xFF232323),
                  Color(0xFF2D2D2D),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          message,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Created: ${DateFormat.yMMMd().format(createdAt)}',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
