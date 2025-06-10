import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:v_shape_app/models/attendence.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'owner_profile_screen.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _searchQuery = '';
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final screenWidth = MediaQuery.of(context).size.width;

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
              _buildCustomAppBar(screenWidth),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth > 1200 ? 1000 : double.infinity,
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSearchBar(screenWidth),
                        SizedBox(height: 16),
                        Expanded(
                            child: _buildCustomerList(
                                customersAsync, screenWidth)),
                        if (_selectedCustomer != null)
                          _buildMarkPresentButton(screenWidth),
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

  Widget _buildCustomAppBar(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E2DE2), // Vivid Purple
            Color(0xFF4A00E0), // Brand Gold Gradient
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
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 1200 ? 1000 : double.infinity,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 40), // For balance
              Text(
                'Mark Attendance',
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OwnerProfileScreen()),
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

  Widget _buildSearchBar(double screenWidth) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth > 800 ? 600 : double.infinity,
        maxHeight: 60,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFFD700).withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerList(
      AsyncValue<List<Customer>> customersAsync, double screenWidth) {
    return customersAsync.when(
      data: (customers) {
        final filteredCustomers = customers
            .where((customer) => customer.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = screenWidth > 600 && screenWidth <= 1200;
            final isDesktop = screenWidth > 1200;

            if (isDesktop) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) =>
                    _buildCustomerCard(filteredCustomers[index], screenWidth),
              );
            } else if (isTablet) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) =>
                    _buildCustomerCard(filteredCustomers[index], screenWidth),
              );
            } else {
              return ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) =>
                    _buildCustomerCard(filteredCustomers[index], screenWidth),
              );
            }
          },
        );
      },
      loading: () => ShimmerLoading(),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, double screenWidth) {
    final isSelected = _selectedCustomer?.id == customer.id;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isDesktop || isTablet ? 4 : 8),
        constraints: BoxConstraints(
          maxHeight: isDesktop ? 80 : (isTablet ? 90 : double.infinity),
          maxWidth: isDesktop ? 300 : double.infinity,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    Color(0xFF8E2DE2).withOpacity(0.3),
                    Color(0xFF4A00E0).withOpacity(0.3),
                  ]
                : [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
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
          border: isSelected
              ? Border.all(color: Color(0xFF8E2DE2), width: 2)
              : null,
        ),
        child: ListTile(
          dense: isDesktop || isTablet,
          leading: customer.profilePic != null &&
                  customer.profilePic!.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.black.withOpacity(0.95),
                        insetPadding: EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            Center(
                              child: Hero(
                                tag: 'profile-pic-attendance-${customer.id}',
                                child: Image.memory(
                                  base64Decode(customer.profilePic!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.white, size: 30),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'profile-pic-attendance-${customer.id}',
                    child: CircleAvatar(
                      radius: isDesktop ? 20 : 24,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          MemoryImage(base64Decode(customer.profilePic!)),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: isDesktop ? 20 : 24,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.person,
                      size: isDesktop ? 20 : 24, color: Colors.grey.shade600),
                ),
          title: Text(
            customer.name,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: isDesktop ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'ID: ${customer.id.substring(0, 8)}',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: isDesktop ? 12 : 14,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedCustomer = customer;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMarkPresentButton(double screenWidth) {
    final isDesktop = screenWidth > 1200;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : double.infinity,
          maxHeight: isDesktop ? 200 : double.infinity,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8E2DE2),
              Color(0xFF4A00E0), // Brand Gold Gradient
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8E2DE2).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center,
                    color: Colors.white, size: isDesktop ? 24 : 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hey ${_selectedCustomer!.name.split(' ')[0]}!',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: isDesktop ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Light Weight Baby! 💪',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: isDesktop ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _markAttendance(context, _selectedCustomer!),
                borderRadius: BorderRadius.circular(15),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: isDesktop ? 12 : 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: isDesktop ? 20 : 24,
                          color: Color(0xFF6B46C1),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Mark Present - ${DateFormat.yMMMd().format(DateTime.now())}',
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B46C1),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Click here to mark your attendance',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: isDesktop ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 500))
        .slideY(begin: 0.2, end: 0);
  }

  Future<void> _markAttendance(BuildContext context, Customer customer) async {
    // Check if membership has expired
    final today = DateTime.now();
    final endDate = customer.endDate;
    final daysUntilExpiration =
        endDate.difference(DateTime(today.year, today.month, today.day)).inDays;

    if (daysUntilExpiration < 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Color(0xFF2C3E50),
          title: Text(
            'Membership Expired',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
              SizedBox(height: 16),
              Text(
                'Dear ${customer.name},',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your gym membership has expired on ${DateFormat.yMMMd().format(endDate)}. To continue enjoying our facilities and mark your attendance, please renew your membership.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                setState(() =>
                    _selectedCustomer = null); // Clear the selected customer
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Color(0xFF6B46C1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final firebaseService = ref.read(firebaseServiceProvider);
    final hasCheckedIn = await firebaseService.hasCheckedInToday(customer.id);

    if (hasCheckedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Color(0xFF2C3E50),
          title: Text(
            'Already Checked In',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You have already marked attendance for today.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                setState(() =>
                    _selectedCustomer = null); // Clear the selected customer
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Color(0xFF6B46C1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final attendance = Attendance(
      id: Uuid().v4(),
      customerId: customer.id,
      timestamp: DateTime.now(),
    );
    await firebaseService.addAttendance(attendance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Color(0xFF2C3E50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text(
              'Attendance Marked Successfully!',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${DateFormat.yMMMd().format(DateTime.now())}',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedCustomer = null); // Clear selection
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Color(0xFF6B46C1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
