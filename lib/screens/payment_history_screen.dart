import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/revenue_history.dart';
import '../services/firebase_service.dart';
import '../providers/firebase_provider.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const PaymentHistoryScreen({
    required this.customerId,
    required this.customerName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8E2DE2), // Vivid Purple
                Color(0xFF4A00E0), // Deep Purple
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              Expanded(
                child: FutureBuilder<List<RevenueHistory>>(
                  future: ref
                      .read(firebaseServiceProvider)
                      .getCustomerRevenueHistory(customerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFFB81C)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text('No transactions found.',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }
                    return ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        SizedBox(height: 8),
                        ...snapshot.data!.map((tx) => Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (tx.paymentType == 'renewal'
                                            ? Color(0xFFFFB81C)
                                            : Color(0xFF4CAF50))
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    tx.paymentType == 'renewal'
                                        ? Icons.refresh
                                        : Icons.person_add,
                                    color: tx.paymentType == 'renewal'
                                        ? Color(0xFFFFB81C)
                                        : Color(0xFF4CAF50),
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  tx.paymentType == 'renewal'
                                      ? 'Renewal'
                                      : 'New Membership',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  '₹${tx.amount.toStringAsFixed(0)} • ${DateFormat('MMM d, yyyy').format(tx.paymentDate)}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
