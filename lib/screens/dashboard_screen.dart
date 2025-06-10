import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'package:v_shape_app/screens/clients_screen.dart';

import 'package:v_shape_app/screens/expiring_members_screen.dart';
import 'package:v_shape_app/screens/owner_profile_screen.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import '../widgets/shimmer_loading.dart';

// Import the entire flutter_animate package and its extensions
import 'package:flutter_animate/flutter_animate.dart';

import 'customer_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onViewAllMembers;
  DashboardScreen({this.onViewAllMembers, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF1A1A2E), // Brand dark gradient
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: customersAsync.when(
                  data: (customers) => _buildDashboard(context, customers),
                  loading: () => ShimmerLoading(),
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
      // bottomNavigationBar: _buildBottomNavigationBar(context),
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
            Color(0xFF4A00E0), // Deep Purple
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'V Shape U Fitness studio',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // IconButton(
              //   icon: Icon(Icons.notifications_outlined, color: Colors.white),
              //   onPressed: () {},
              // ),
              IconButton(
                icon: Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OwnerProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 500))
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildDashboard(BuildContext context, List<Customer> customers) {
    final activeCustomers =
        customers.where((c) => c.endDate.isAfter(DateTime.now())).length;
    final expiredCustomers = customers.length - activeCustomers;
    final selfTraining =
        customers.where((c) => c.trainingType == 'Self').length;
    final personalTraining =
        customers.where((c) => c.trainingType == 'Personal').length;

    return Container(
      child: RefreshIndicator(
        onRefresh: () async {
          // Remove the ref.refresh call since we don't have access to ref here
          // Instead, we'll handle refresh at the parent level
        },
        backgroundColor: Color(0xFF8E2DE2),
        color: Color(0xFF1E1E1E),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints:
                  BoxConstraints(maxWidth: 800), // Constrain overall width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _buildSearchBar(context),
                  // SizedBox(height: 20),
                  Text(
                    "Welcome to V Shape U Fitness💪",
                    style: GoogleFonts.rajdhani(
                        color: Color(0xFFF5F5F5),
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "A Smarter Way To Get Fit",
                    style: GoogleFonts.montserrat(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  _buildStatCardsGrid(customers.length, activeCustomers,
                      expiredCustomers, context, customers),
                  SizedBox(height: 20),
                  _buildTrainingStatsCard(
                      selfTraining, personalTraining, customers),
                  SizedBox(height: 24),
                  _buildSectionTitle(
                      context, 'Recent Members', Icons.people_alt_outlined),
                  SizedBox(height: 12),
                  _buildRecentMembers(context, customers),
                  SizedBox(height: 20),
                  // _buildViewAllButton(context),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search clients...',
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 600))
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildStatCardsGrid(int total, int active, int expired,
      BuildContext context, List<Customer> customers) {
    // Calculate new members this week
    final today = DateTime.now();
    final weekAgo = today.subtract(Duration(days: 7));
    final newMembersThisWeek = customers
        .where(
            (c) => c.startDate.isAfter(weekAgo) && c.startDate.isBefore(today))
        .length;

    // Calculate renewal rate
    final expiringThisMonth = customers
        .where((c) =>
            c.endDate.isAfter(today) &&
            c.endDate.isBefore(today.add(Duration(days: 3))))
        .length;

    // Calculate average attendance
    final totalAttendance =
        customers.where((c) => c.trainingType == 'Personal').length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: 320, // Limit maximum height
      ),
      child: GridView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600
              ? 4
              : 2, // 4 columns on wide screens
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: MediaQuery.of(context).size.width > 600
              ? 1.1
              : 1.3, // Adjust aspect ratio for wide screens
        ),
        children: [
          _buildStatCard(
            'Total Clients',
            total.toString(),
            Icons.groups_outlined,
            [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            context,
          )
              .animate()
              .fadeIn(
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 100))
              .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
          _buildStatCard(
            'Active',
            active.toString(),
            Icons.verified_user_outlined,
            [Color(0xFF06BEB6), Color(0xFF48B1BF)],
            context,
          )
              .animate()
              .fadeIn(
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 200))
              .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
          _buildStatCard(
            'New This Week',
            newMembersThisWeek.toString(),
            Icons.trending_up_outlined,
            [Color(0xFFFF5F6D), Color(0xFFFFC371)],
            context,
          )
              .animate()
              .fadeIn(
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 300))
              .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
          _buildStatCard(
            'Expiring Soon',
            expiringThisMonth.toString(),
            Icons.event_available_outlined,
            [Color(0xFF00B4DB), Color(0xFF0083B0)],
            context,
          )
              .animate()
              .fadeIn(
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 400))
              .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      List<Color> gradientColors, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == 'Expiring Soon') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExpiringMembersScreen()),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 150, // Limit card height
          maxWidth: 200, // Limit card width
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (title == 'Expiring Soon')
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingStatsCard(
      int selfTraining, int personalTraining, List<Customer> customers) {
    final generalTraining =
        customers.where((c) => c.trainingType == 'General').length;
    final total = selfTraining + personalTraining + generalTraining;

    return Container(
      constraints: BoxConstraints(
        maxHeight: 400, // Limit maximum height
        maxWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8E2DE2).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Color(0xFF8E2DE2),
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Training Distribution",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            //SizedBox(height: 10),
            if (total == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No members yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Limit the pie chart size
                    final chartSize = MediaQuery.of(context).size.width > 600
                        ? 200.0 // Fixed size for larger screens
                        : constraints.maxWidth * 0.5;

                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: chartSize,
                            constraints: BoxConstraints(
                              maxHeight: 200, // Maximum height for pie chart
                              maxWidth: 300, // Maximum width for pie chart
                            ),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                                sections: [
                                  PieChartSectionData(
                                    value: selfTraining.toDouble(),
                                    color: Color(0xFF6C63FF),
                                    title: total > 0
                                        ? '${(selfTraining / total * 100).round()}%'
                                        : '0%',
                                    radius: chartSize * 0.4,
                                    titleStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: personalTraining.toDouble(),
                                    color: Color(0xFF06BEB6),
                                    title: total > 0
                                        ? '${(personalTraining / total * 100).round()}%'
                                        : '0%',
                                    radius: chartSize * 0.4,
                                    titleStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: generalTraining.toDouble(),
                                    color: Color(0xFF8E2DE2),
                                    title: total > 0
                                        ? '${(generalTraining / total * 100).round()}%'
                                        : '0%',
                                    radius: chartSize * 0.4,
                                    titleStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // _buildLegendItem('Self Training',
                              //     selfTraining.toString(), Color(0xFF6C63FF)),
                              SizedBox(height: 12),
                              _buildLegendItem(
                                  'Personal Training',
                                  personalTraining.toString(),
                                  Color(0xFF06BEB6)),
                              SizedBox(height: 12),
                              _buildLegendItem(
                                  'General Training',
                                  generalTraining.toString(),
                                  Color(0xFF8E2DE2)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: Duration(milliseconds: 800),
            delay: Duration(milliseconds: 500))
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildLegendItem(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Color(0xFF8E2DE2),
          size: 24,
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ).animate().fadeIn(
        duration: Duration(milliseconds: 800),
        delay: Duration(milliseconds: 600));
  }

  Widget _buildRecentMembers(BuildContext context, List<Customer> customers) {
    // Sort customers by start date in descending order (most recent first)
    final recent = customers.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // Take only the 5 most recent members
    final recentMembers = recent.take(5).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: recentMembers.length,
      itemBuilder: (context, index) {
        final customer = recentMembers[index];
        return Hero(
          tag: 'customer-${customer.id}',
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
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF6C63FF).withOpacity(0.1),
                  backgroundImage: customer.profilePic != null &&
                          customer.profilePic!.isNotEmpty
                      ? MemoryImage(base64Decode(customer.profilePic!))
                      : null,
                  child: customer.profilePic == null ||
                          customer.profilePic!.isEmpty
                      ? Text(
                          customer.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  customer.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${DateFormat.yMMMd().format(customer.startDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: customer.trainingType == 'Personal'
                            ? Color(0xFF06BEB6).withOpacity(0.2)
                            : Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        customer.trainingType,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: customer.trainingType == 'Personal'
                              ? Color(0xFF06BEB6)
                              : Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerDetailScreen(customer: customer),
                        ),
                      );
                    },
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerDetailScreen(customer: customer),
                    ),
                  );
                },
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
                duration: Duration(milliseconds: 800),
                delay: Duration(milliseconds: (700 + index * 100)))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF8E2DE2),
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            shadowColor: Color(0xFF8E2DE2).withOpacity(0.5),
          ),
          onPressed: () {
            // Navigate to all members
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientsScreen(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View All Members',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
        duration: Duration(milliseconds: 800),
        delay: Duration(milliseconds: 1200));
  }

  Color _getRandomColor(String id) {
    final colors = [
      Color(0xFF8E2DE2),
      Color(0xFF4A00E0),
      Color(0xFF000000),
      Color(0xFF1976D2),
    ];

    return colors[id.hashCode % colors.length];
  }
}
