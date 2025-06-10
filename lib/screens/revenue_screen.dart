import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/firebase_provider.dart';
import '../models/revenue_history.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  bool _isLoading = true;
  double _totalRevenue = 0;
  double _todayRevenue = 0;
  double _weeklyRevenue = 0;
  Map<String, double> _monthlyRevenue = {};
  List<RevenueHistory> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      _totalRevenue = await firebaseService.getTotalRevenue();
      _todayRevenue = await firebaseService.getTodayRevenue();
      _weeklyRevenue = await firebaseService.getWeeklyRevenue();
      _monthlyRevenue = await firebaseService.getMonthlyRevenue();

      // Get recent transactions
      final history = await firebaseService.getRecentTransactions();
      if (mounted) {
        setState(() {
          _recentTransactions = history;
        });
      }
    } catch (e) {
      print('Error loading revenue data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFB81C),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRevenueData,
                        color: Color(0xFFFFB81C),
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRevenueCards(),
                              SizedBox(height: 24),
                              _buildMonthlyRevenueList(),
                              SizedBox(height: 24),
                              _buildRecentTransactions(),
                            ],
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E2DE2),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wrap the Column in Flexible to prevent overflow
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Overview',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your gym\'s financial performance',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          SizedBox(width: 12), // spacing between text and icon
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 400))
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildRevenueCards() {
    return Column(
      children: [
        _buildRevenueCard(
          title: 'Total Revenue',
          amount: _totalRevenue,
          icon: Icons.account_balance_wallet_rounded,
          color: Color(0xFF4CAF50),
        ).animate().fadeIn(
            duration: Duration(milliseconds: 500),
            delay: Duration(milliseconds: 100)),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                title: 'Today\'s Income',
                amount: _todayRevenue,
                icon: Icons.today_rounded,
                color: Color(0xFF2196F3),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildRevenueCard(
                title: 'This Week',
                amount: _weeklyRevenue,
                icon: Icons.calendar_view_week_rounded,
                color: Color(0xFFFF9800),
              ),
            ),
          ],
        ).animate().fadeIn(
            duration: Duration(milliseconds: 500),
            delay: Duration(milliseconds: 200)),
      ],
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: color,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRevenueList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Revenue',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ..._monthlyRevenue.entries.map((entry) => _buildMonthlyRevenueItem(
              month: entry.key,
              amount: entry.value,
            )),
      ],
    ).animate().fadeIn(
        duration: Duration(milliseconds: 500),
        delay: Duration(milliseconds: 300));
  }

  Widget _buildMonthlyRevenueItem({
    required String month,
    required double amount,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB81C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFFFB81C),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                month,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            currencyFormat.format(amount),
            style: GoogleFonts.montserrat(
              color: Color(0xFFFFB81C),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ..._recentTransactions
            .map((transaction) => _buildTransactionItem(transaction)),
      ],
    ).animate().fadeIn(
        duration: Duration(milliseconds: 500),
        delay: Duration(milliseconds: 400));
  }

  Widget _buildTransactionItem(RevenueHistory transaction) {
    final isNew = transaction.paymentType == 'new';
    final isRenewal = transaction.paymentType == 'renewal';
    final isFeeAdjustment = transaction.paymentType == 'fee_adjustment';
    final isAdjustment = transaction.paymentType == 'adjustment';
    final isCorrection = transaction.paymentType == 'correction';

    // Set Icon and color based on transaction type
    IconData icon = isNew
        ? Icons.person_add_rounded
        : isRenewal
            ? Icons.refresh_rounded
            : isFeeAdjustment
                ? Icons.edit_outlined
                : isAdjustment || isCorrection
                    ? Icons.update
                    : Icons.attach_money;

    Color color = isNew
        ? Color(0xFF4CAF50)
        : isRenewal
            ? Color(0xFFFFB81C)
            : isFeeAdjustment
                ? Color(0xFF2196F3)
                : isAdjustment || isCorrection
                    ? Color(0xFF2196F3)
                    : Color(0xFF9C27B0);

    // Format the transaction description
    String transactionType = isNew
        ? 'New Membership'
        : isRenewal
            ? 'Renewal'
            : isFeeAdjustment
                ? 'Fee Adjustment'
                : isAdjustment
                    ? 'Fee Adjustment'
                    : isCorrection
                        ? 'Fee Correction'
                        : 'Payment';

    // Add a "+" sign for positive adjustments
    String amountDisplay;
    if (isFeeAdjustment && transaction.amount > 0) {
      amountDisplay = '+' + currencyFormat.format(transaction.amount);
    } else {
      amountDisplay = currencyFormat.format(transaction.amount);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.customerName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${transactionType} • ${DateFormat('MMM d, y').format(transaction.paymentDate)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountDisplay,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
