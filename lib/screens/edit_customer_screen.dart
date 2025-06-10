import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import 'add_member_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../utils/web_image_picker_stub.dart'
    if (dart.library.html) '../utils/web_image_picker.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final bool isRenewal;

  EditCustomerScreen({
    required this.customer,
    this.isRenewal = false,
  });

  @override
  _EditCustomerScreenState createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _weightController;
  late TextEditingController _feesController;
  late String _gender;
  late String _trainingType;
  late String _paymentStatus;
  late String _paymentType;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _dateOfBirth;
  bool _isSubmitting = false;
  String? _profilePicBase64;
  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _weightController =
        TextEditingController(text: widget.customer.weight.toString());
    _feesController =
        TextEditingController(text: widget.customer.fees.toString());
    _gender = widget.customer.gender;
    _trainingType = widget.customer.trainingType;
    _startDate = widget.customer.startDate;
    _endDate = widget.customer.endDate;
    _dateOfBirth = widget.customer.dateOfBirth;
    _paymentStatus = widget.customer.paymentStatus;
    _paymentType = widget.customer.paymentType;
    _profilePicBase64 = widget.customer.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Store the original fees for comparison
      final oldFees = widget.customer.fees;

      final updatedCustomer = Customer(
        id: widget.customer.id,
        name: _nameController.text,
        dateOfBirth: _dateOfBirth,
        phoneNumber: _phoneController.text,
        gender: _gender,
        weight: double.parse(_weightController.text),
        trainingType: _trainingType,
        startDate: _startDate,
        endDate: _endDate,
        fees: double.parse(_feesController.text),
        paymentStatus: _paymentStatus,
        paymentType: _paymentType,
        planId: widget.customer.planId,
        profilePic: _profilePicBase64,
      );

      // Use new method to update customer and handle fee changes in revenue history
      await ref
          .read(firebaseServiceProvider)
          .updateCustomerWithRevenueHistory(updatedCustomer, oldFees);

      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      _showSuccessDialog();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      final bytes = await pickWebImage();
      if (bytes == null) {
        // Show error or user cancelled
        return;
      }
      setState(() {
        _profilePicBase64 = base64Encode(bytes);
      });
    } else {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profilePicBase64 = base64Encode(bytes);
          _pickedImageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _removeProfilePic() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Profile Picture',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this profile picture? This cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _profilePicBase64 = null;
              });
              // Update Firestore to remove the profile picture
              final updatedCustomer = Customer(
                id: widget.customer.id,
                name: widget.customer.name,
                phoneNumber: widget.customer.phoneNumber,
                dateOfBirth: widget.customer.dateOfBirth,
                gender: widget.customer.gender,
                weight: widget.customer.weight,
                startDate: widget.customer.startDate,
                endDate: widget.customer.endDate,
                fees: widget.customer.fees,
                trainingType: widget.customer.trainingType,
                profilePic: '',
                paymentStatus: widget.customer.paymentStatus,
                paymentType: widget.customer.paymentType,
                planId: widget.customer.planId,
              );
              ref.read(firebaseServiceProvider).updateCustomer(updatedCustomer);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
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
              'Member Updated Successfully!',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Color(0xFF8E2DE2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          ),
        ),
        title: Text(
          'Edit Member',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _profilePicBase64 != null &&
                                        _profilePicBase64!.isNotEmpty
                                    ? () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            backgroundColor:
                                                Colors.black.withOpacity(0.95),
                                            insetPadding: EdgeInsets.all(16),
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child: Hero(
                                                    tag: 'profile-pic-edit',
                                                    child: Image.memory(
                                                      base64Decode(
                                                          _profilePicBase64!),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: IconButton(
                                                    icon: Icon(Icons.close,
                                                        color: Colors.white,
                                                        size: 30),
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Hero(
                                  tag: 'profile-pic-edit',
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor:
                                        Color(0xFF8E2DE2).withOpacity(0.2),
                                    backgroundImage: _profilePicBase64 !=
                                                null &&
                                            _profilePicBase64!.isNotEmpty
                                        ? MemoryImage(
                                            base64Decode(_profilePicBase64!))
                                        : null,
                                    child: (_profilePicBase64 == null ||
                                            _profilePicBase64!.isEmpty)
                                        ? Text(
                                            _nameController.text.isNotEmpty
                                                ? _nameController.text
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                : '',
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
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.photo_camera,
                                        color: Color(0xFFFFA500)),
                                    tooltip: 'Take Photo',
                                    onPressed: () =>
                                        _pickImage(ImageSource.camera),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.photo_library,
                                        color: Color(0xFFFFA500)),
                                    tooltip: 'Choose from Gallery',
                                    onPressed: () =>
                                        _pickImage(ImageSource.gallery),
                                  ),
                                  if (_profilePicBase64 != null &&
                                      _profilePicBase64!.isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      tooltip: 'Remove',
                                      onPressed: _removeProfilePic,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildSectionTitle('Personal Information'),
                        SizedBox(height: 16),
                        _buildTextField(_nameController, 'Name', Icons.person),
                        SizedBox(height: 16),
                        _buildTextField(
                            _phoneController, 'Phone Number', Icons.phone,
                            keyboardType: TextInputType.phone),
                        SizedBox(height: 16),
                        _buildTextField(_weightController, 'Weight (kg)',
                            Icons.fitness_center,
                            keyboardType: TextInputType.number),
                        SizedBox(height: 16),
                        _buildDatePicker('Date of Birth', _dateOfBirth,
                            (date) => setState(() => _dateOfBirth = date)),
                        SizedBox(height: 16),
                        _buildDropdown('Gender', ['Male', 'Female'], _gender,
                            (value) => setState(() => _gender = value!)),
                        SizedBox(height: 24),
                        _buildSectionTitle('Membership Details'),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _feesController,
                                'Fees',
                                Icons.attach_money,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
                                'Payment Status',
                                ['Paid', 'Pending'],
                                _paymentStatus,
                                (value) =>
                                    setState(() => _paymentStatus = value!),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildDropdown(
                          'Payment Type',
                          ['CASH', 'GPAY', 'PHONEPE', 'PAYTM'],
                          _paymentType,
                          (value) => setState(() => _paymentType = value!),
                        ),
                        SizedBox(height: 16),
                        _buildDatePicker('Start Date', _startDate,
                            (date) => setState(() => _startDate = date)),
                        SizedBox(height: 16),
                        _buildDatePicker('End Date', _endDate,
                            (date) => setState(() => _endDate = date)),
                        SizedBox(height: 32),
                        _buildSubmitButton(),
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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFFFB81C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFFFB81C)),
        ),
      ),
      dropdownColor: Color(0xFF2C3E50),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker(String label, DateTime selectedDate,
      void Function(DateTime) onDateSelected) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Color(0xFFFFB81C),
                  onPrimary: Colors.white,
                  surface: Color(0xFF232323),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: Color(0xFF232323),
              ),
              child: child!,
            );
          },
        );
        if (date != null) onDateSelected(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0xFFFFB81C)),
          ),
        ),
        child: Text(
          DateFormat.yMMMd().format(selectedDate),
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        if (!widget.isRenewal) ...[
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFFFA500),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
                shadowColor: Color(0xFFFFA500).withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.save,
                          size: 22,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Update Member',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _handleRenewal(context),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 5,
              shadowColor: Color(0xFF4CAF50).withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh,
                  size: 22,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text(
                  'Renew Membership',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleRenewal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberScreen(
          existingCustomer: widget.customer,
          isRenewal: true,
        ),
      ),
    );
  }

  void _downloadPdf(BuildContext context) {
    // Implementation of _downloadPdf method
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    // Implementation of _confirmDelete method
  }
}
