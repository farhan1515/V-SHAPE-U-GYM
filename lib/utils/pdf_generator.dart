import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/customer.dart';

class PdfGenerator {
  static Future<pw.Document> generateCustomerReceipt(Customer customer) async {
    final pdf = pw.Document();
    // Using a more professional font combination with Unicode support
    final font = pw.Font.helveticaBold();
    final regularFont = pw.Font.helvetica();
    final dateFormat = DateFormat.yMMMd();

    // Define vibrant color palette with proper PDF colors
    final primaryColor = PdfColor.fromInt(0xFF6B46C1); // Deep purple
    final secondaryColor = PdfColor.fromInt(0xFF8E2DE2); // Vibrant purple
    final accentColor = PdfColor.fromInt(0xFF00C9FF); // Bright blue
    final successColor = PdfColor.fromInt(0xFF28A745); // Vibrant green
    final warningColor = PdfColor.fromInt(0xFFFFC107); // Bright yellow
    final darkColor = PdfColor.fromInt(0xFF2C3E50); // Dark blue-gray
    final lightColor = PdfColor.fromInt(0xFFF8F9FA); // Very light gray
    final textColor = PdfColor.fromInt(0xFF212529); // Dark text for contrast
    final lightGrey = PdfColor.fromInt(0xFFE0E0E0); // Light grey for borders
    final semiTransparentWhite = PdfColor.fromInt(0xE6FFFFFF); // 90% white
    final semiTransparentBlack = PdfColor.fromInt(0x4D000000); // 30% black
    final sectionBgColor =
        PdfColor.fromInt(0xFFF5F5F5); // Light gray for sections

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: font,
        ),
        build: (pw.Context context) => [
          pw.Container(
            color: lightColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with Gym Name
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(20),
                      bottomRight: pw.Radius.circular(20),
                    ),
                    boxShadow: [
                      pw.BoxShadow(
                        color: semiTransparentBlack,
                        blurRadius: 10,
                        offset: PdfPoint(0, 5),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'V Shape U Fitness',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'MEMBERSHIP RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: semiTransparentWhite,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Receipt Number and Date
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // pw.Text(
                      //   'Receipt #${customer.id.substring(0, 8).toUpperCase()}',
                      //   style: pw.TextStyle(
                      //     fontSize: 16,
                      //     color: secondaryColor,
                      //     fontWeight: pw.FontWeight.bold,
                      //   ),
                      // ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color:
                              PdfColor.fromInt(0x3300C9FF), // 20% accent color
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          'Date: ${dateFormat.format(DateTime.now())}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: darkColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Customer Information
                _buildSectionHeader('PERSONAL INFORMATION', secondaryColor),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: lightGrey, width: 1.5),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey300,
                        blurRadius: 10,
                        offset: PdfPoint(0, 5),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      _buildInfoRow('Name', customer.name, textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow('Date of Birth',
                          dateFormat.format(customer.dateOfBirth), textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow('Phone', customer.phoneNumber, textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow('Gender', customer.gender, textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow(
                          'Weight', '${customer.weight} kg', textColor),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                // Membership Details
                _buildSectionHeader('MEMBERSHIP DETAILS', secondaryColor),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white, // Changed to white for consistency
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: lightGrey, width: 1.5),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey300,
                        blurRadius: 10,
                        offset: PdfPoint(0, 5),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      _buildInfoRow(
                          'Training Type', customer.trainingType, textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow('Start Date',
                          dateFormat.format(customer.startDate), textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow('End Date',
                          dateFormat.format(customer.endDate), textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow('Fees', 'Rs. ${customer.fees}', textColor),
                      _buildDivider(lightGrey),
                      _buildInfoRow(
                        'Payment Status',
                        customer.paymentStatus.toUpperCase(),
                        customer.paymentStatus == 'Paid'
                            ? successColor
                            : warningColor,
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                // Plan Information (if applicable)
                // if (customer.planId != null) ...[
                //   pw.SizedBox(height: 25),
                //   _buildSectionHeader('PLAN INFORMATION', secondaryColor),
                //   pw.Container(
                //     margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                //     padding: const pw.EdgeInsets.all(20),
                //     decoration: pw.BoxDecoration(
                //       color: PdfColors.white,
                //       borderRadius: pw.BorderRadius.circular(15),
                //       border: pw.Border.all(color: lightGrey, width: 1.5),
                //       boxShadow: [
                //         pw.BoxShadow(
                //           color: PdfColors.grey300,
                //           blurRadius: 10,
                //           offset: PdfPoint(0, 5),
                //         ),
                //       ],
                //     ),
                //     child: pw.Column(
                //       children: [
                //         _buildInfoRow('Plan ID', customer.planId!, textColor),
                //       ],
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [darkColor, PdfColor.fromInt(0xFF1A1A2E)],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(20),
              topRight: pw.Radius.circular(20),
            ),
            boxShadow: [
              pw.BoxShadow(
                color: semiTransparentBlack,
                blurRadius: 15,
                offset: PdfPoint(0, -5),
              ),
            ],
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'THANK YOU FOR CHOOSING V Shape U Fitness!',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on ${dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: semiTransparentWhite,
                  letterSpacing: 0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Contact: info@vshapefitness.com | Phone: +91 90145 20272',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xB3FFFFFF), // 70% white
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    PdfColor color, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColor.fromInt(0xCC212529), // 80% text color
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDivider(PdfColor color) {
    return pw.Container(
      height: 1,
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromInt(0x1A000000), // 10% black
            color,
            PdfColor.fromInt(0x1A000000), // 10% black
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
