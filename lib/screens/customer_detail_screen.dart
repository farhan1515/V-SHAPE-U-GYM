import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // Added for base64Decode

import 'package:url_launcher/url_launcher.dart';
import 'package:v_shape_app/models/revenue_history.dart';
import 'package:v_shape_app/screens/payment_history_screen.dart';
import 'package:v_shape_app/utils/pdf_generator.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import 'edit_customer_screen.dart';
import 'attendence_history_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:io' as io;

import 'package:universal_html/html.dart' as html;

class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;
  final VoidCallback? onViewAllMembers;

  CustomerDetailScreen({required this.customer, this.onViewAllMembers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E1E1E), // Brand dark
              Color(0xFF2D2D2D), // Brand dark gradient
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context, ref),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context),
                      SizedBox(height: 24),
                      _buildSectionTitle('Personal Information'),
                      SizedBox(height: 16),
                      _buildInfoCard([
                        _buildInfoRow('Name', customer.name, Icons.person),
                        _buildInfoRow(
                            'Date of Birth',
                            DateFormat.yMMMd().format(customer.dateOfBirth),
                            Icons.cake),
                        _buildInfoRow(
                            'Phone', customer.phoneNumber, Icons.phone),
                        _buildInfoRow(
                            'Gender', customer.gender, Icons.transgender),
                        _buildInfoRow('Weight', '${customer.weight} kg',
                            Icons.fitness_center),
                      ]),
                      SizedBox(height: 24),
                      _buildSectionTitle('Membership Details'),
                      SizedBox(height: 16),
                      _buildInfoCard([
                        _buildInfoRow('Training Type', customer.trainingType,
                            Icons.fitness_center),
                        _buildInfoRow(
                            'Start Date',
                            DateFormat.yMMMd().format(customer.startDate),
                            Icons.calendar_today),
                        _buildInfoRow(
                            'End Date',
                            DateFormat.yMMMd().format(customer.endDate),
                            Icons.event_available),
                        _buildInfoRow(
                            'Fees', '₹${customer.fees}', Icons.attach_money),
                        _buildInfoRow(
                          'Payment Status',
                          customer.paymentStatus,
                          customer.paymentStatus == 'Paid'
                              ? Icons.check_circle
                              : Icons.pending_actions,
                          valueColor: customer.paymentStatus == 'Paid'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        _buildInfoRow(
                          'Payment Type',
                          customer.paymentType,
                          Icons.money,
                        ),
                      ]),
                      if (customer.planId != null) ...[
                        SizedBox(height: 24),
                        _buildSectionTitle('Plan Information'),
                        SizedBox(height: 16),
                        _buildInfoCard([
                          _buildInfoRow('Plan ID', customer.planId!,
                              Icons.fitness_center),
                        ]),
                      ],
                      SizedBox(height: 32),
                      _buildActionButtons(context, ref),
                      // _buildTransactionHistory(context, ref),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, WidgetRef ref) {
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT SECTION
          Flexible(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Member Details',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // RIGHT SECTION
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _sendWhatsAppMessage(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF25D366),
                    // gradient: LinearGradient(
                    //   colors: [
                    //     Colors.white.withOpacity(0.15),
                    //     Colors.white.withOpacity(0.05),
                    //   ],
                    //   begin: Alignment.topLeft,
                    //   end: Alignment.bottomRight,
                    // ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.message_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'WhatsApp',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: customer.profilePic != null &&
                    customer.profilePic!.isNotEmpty
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.black.withOpacity(0.95),
                        insetPadding: EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            Center(
                              child: Hero(
                                tag: 'profile-pic-detail-${customer.id}',
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
                  }
                : null,
            child: Hero(
              tag: 'profile-pic-detail-${customer.id}',
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFF8E2DE2).withOpacity(0.2),
                backgroundImage: customer.profilePic != null &&
                        customer.profilePic!.isNotEmpty
                    ? MemoryImage(base64Decode(customer.profilePic!))
                    : null,
                child: (customer.profilePic == null ||
                        customer.profilePic!.isEmpty)
                    ? Text(
                        customer.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            customer.name,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: customer.trainingType == 'Personal'
                      ? Color(0xFF06BEB6).withOpacity(0.2)
                      : Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  customer.trainingType,
                  style: GoogleFonts.poppins(
                    color: customer.trainingType == 'Personal'
                        ? Color(0xFF06BEB6)
                        : Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // SizedBox(width: 12),
              // Container(
              //   decoration: BoxDecoration(
              //     color: Color(0xFF8E2DE2).withOpacity(0.2),
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   child: TextButton.icon(
              //     icon: Icon(Icons.history, color: Colors.white, size: 20),
              //     label: Text(
              //       'History',
              //       style: GoogleFonts.poppins(
              //         color: Colors.white,
              //         fontSize: 14,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) =>
              //               AttendanceHistoryScreen(customer: customer),
              //         ),
              //       );
              //     },
              //     style: TextButton.styleFrom(
              //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(20),
              //       ),
              //     ),
              //   ),
              // ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8E2DE2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton.icon(
                  icon: Icon(Icons.payment, color: Colors.white, size: 20),
                  label: Text(
                    'Payment History',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentHistoryScreen(
                          customerId: customer.id,
                          customerName: customer.name,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditCustomerScreen(customer: customer),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                label: Text('Edit Member',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8E2DE2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmationDialog(context, ref),
                icon: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                label: Text('Delete',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _downloadPdf(context),
          icon: Icon(
            Icons.download,
            color: Colors.white,
          ),
          label: Text('Download PDF Receipt',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF06BEB6),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = await PdfGenerator.generateCustomerReceipt(customer);
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // For Web
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "${customer.name}_receipt.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For Android/iOS/macOS/Windows/Linux
        final tempDir = await getTemporaryDirectory();
        final file = io.File('${tempDir.path}/${customer.name}_receipt.pdf');
        await file.writeAsBytes(pdfBytes);

        // Optionally open the PDF (mobile only)
        await OpenFile.open(file.path);
      }

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF receipt downloaded successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error generating PDF: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Customer',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(firebaseServiceProvider)
                  .deleteCustomer(customer.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    String phoneNumber = customer.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber'; // Adjust country code as needed
    }

    final today = DateTime.now();
    final endDate = customer.endDate;
    final daysUntilExpiration =
        endDate.difference(DateTime(today.year, today.month, today.day)).inDays;

    String message;
    if (daysUntilExpiration < 0) {
      message =
          "Dear ${customer.name}, your membership at V Shape U Fitness has expired on ${DateFormat.yMMMd().format(endDate)}. Please renew to continue enjoying our services!";
    } else if (daysUntilExpiration == 0) {
      message =
          "Dear ${customer.name}, your membership at V Shape U Fitness expires today! Please renew to continue enjoying our services.";
    } else {
      message =
          "Dear ${customer.name}, your membership at V Shape U Fitness is expiring in $daysUntilExpiration day${daysUntilExpiration > 1 ? 's' : ''} on ${DateFormat.yMMMd().format(endDate)}. Please renew soon!";
    }

    // Clean phone number (remove any '+' and only keep digits)
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Double encode to handle special characters better
    final encodedMessage = Uri.encodeComponent(message);

    // Universal approach - works on both mobile and desktop
    final url = 'https://wa.me/$cleanPhoneNumber?text=$encodedMessage';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        // Always use platformDefault or externalApplication mode to ensure proper handling
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      // Show a more detailed error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error launching WhatsApp: $e\nTried URL: $url',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 8),
        ),
      );
    }
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        child: ElevatedButton(
          onPressed: () {
            if (onViewAllMembers != null) {
              onViewAllMembers!();
            }
          },
          child: Row(
            children: [
              Icon(Icons.view_list),
              SizedBox(width: 8),
              Text('View All Members'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<RevenueHistory>>(
      future: ref
          .read(firebaseServiceProvider)
          .getCustomerRevenueHistory(customer.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text('No transactions found.',
                style: TextStyle(color: Colors.white70)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Text('Transaction History',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 12),
            ...snapshot.data!.map((tx) => ListTile(
                  leading: Icon(
                    tx.paymentType == 'renewal'
                        ? Icons.refresh
                        : Icons.person_add,
                    color: tx.paymentType == 'renewal'
                        ? Colors.orange
                        : Colors.green,
                  ),
                  title: Text(
                    '${tx.paymentType == 'renewal' ? 'Renewal' : 'New Membership'}',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '₹${tx.amount.toStringAsFixed(0)} • ${DateFormat('MMM d, yyyy').format(tx.paymentDate)}',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                )),
          ],
        );
      },
    );
  }
}
