import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../services/firebase_service.dart';
import 'customer_detail_screen.dart';

class ExpiringMembersScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final today = DateTime.now();
    final threeDaysFromNow = today.add(Duration(days: 3));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: customersAsync.when(
                  data: (customers) {
                    final expiringMembers = customers
                        .where((c) =>
                            c.endDate.isAfter(today) &&
                            c.endDate.isBefore(threeDaysFromNow))
                        .toList();

                    if (expiringMembers.isEmpty) {
                      return Center(
                        child: Text(
                          'No memberships expiring soon',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: expiringMembers.length,
                      itemBuilder: (context, index) {
                        final member = expiringMembers[index];
                        final daysUntilExpiry =
                            member.endDate.difference(today).inDays;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerDetailScreen(customer: member),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: _getRandomColor(member.id),
                                backgroundImage: member.profilePic != null &&
                                        member.profilePic!.isNotEmpty
                                    ? MemoryImage(
                                        base64Decode(member.profilePic!))
                                    : null,
                                child: member.profilePic == null ||
                                        member.profilePic!.isEmpty
                                    ? Text(
                                        member.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                member.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Expires: ${DateFormat.yMMMd().format(member.endDate)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: daysUntilExpiry == 0
                                          ? Color(0xFFFFB81C).withOpacity(0.2)
                                          : Color(0xFFF29100).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      daysUntilExpiry == 0
                                          ? 'Expires Today!'
                                          : 'Expires in $daysUntilExpiry days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: daysUntilExpiry == 0
                                            ? Color(0xFFFFB81C)
                                            : Color(0xFFF29100),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error: $error',
                      style: GoogleFonts.poppins(color: Colors.white),
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

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E2DE2), // Vivid Purple
            Color(0xFF4A00E0),
          ],
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
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Expiring Memberships',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 40), // For balance
        ],
      ),
    );
  }

  Color _getRandomColor(String id) {
    final colors = [
      Color(0xFFFFB81C),
      Color(0xFFF29100),
      Color(0xFF000000),
      Color(0xFF1976D2),
    ];

    return colors[id.hashCode % colors.length];
  }
}
