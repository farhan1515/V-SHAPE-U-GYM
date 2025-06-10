import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../utils/web_image_picker_stub.dart'
    if (dart.library.html) '../utils/web_image_picker.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final Customer? existingCustomer;
  final bool isRenewal;

  const AddMemberScreen({
    super.key,
    this.existingCustomer,
    this.isRenewal = false,
  });

  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _feesController = TextEditingController();
  String _gender = 'Male';
  String _trainingType = 'Personal';
  String _paymentStatus = 'Paid';
  String _paymentType = 'CASH';
  DateTime _dateOfBirth = DateTime.now().subtract(Duration(days: 365 * 18));
  DateTime _startDate = DateTime(2025, 1, 1);
  DateTime _endDate = DateTime.now().add(Duration(days: 30));
  bool _isSubmitting = false;
  String? _profilePicBase64;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
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
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
          backgroundColor: Color(0xFF8E2DE2),
        ),
      );
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

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      _nameController.text = widget.existingCustomer!.name;
      _phoneController.text = widget.existingCustomer!.phoneNumber;
      _weightController.text = widget.existingCustomer!.weight.toString();
      _feesController.text = widget.existingCustomer!.fees.toString();
      _gender = widget.existingCustomer!.gender;
      _trainingType = widget.existingCustomer!.trainingType;
      _dateOfBirth = widget.existingCustomer!.dateOfBirth;
      _startDate = widget.existingCustomer!.startDate;
      _endDate = widget.existingCustomer!.endDate;
      _profilePicBase64 = widget.existingCustomer!.profilePic;
      _paymentStatus = widget.existingCustomer!.paymentStatus;
      _paymentType = widget.existingCustomer!.paymentType;
    }
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
      try {
        double? weight = double.tryParse(_weightController.text);
        double? fees = double.tryParse(_feesController.text);

        if (weight == null) {
          throw Exception('Please enter a valid weight');
        }
        if (fees == null) {
          throw Exception('Please enter a valid fee amount');
        }

        if (widget.isRenewal && widget.existingCustomer != null) {
          final updatedCustomer = Customer(
            id: widget.existingCustomer!.id,
            name: _nameController.text,
            dateOfBirth: _dateOfBirth,
            phoneNumber: _phoneController.text,
            gender: _gender,
            weight: weight,
            trainingType: _trainingType,
            startDate: _startDate,
            endDate: _endDate,
            fees: fees,
            paymentStatus: _paymentStatus,
            paymentType: _paymentType,
            profilePic: _profilePicBase64,
          );
          await ref.read(firebaseServiceProvider).renewMembership(
                updatedCustomer: updatedCustomer,
                newStartDate: _startDate,
                newEndDate: _endDate,
                newFees: fees,
              );
        } else {
          final customer = Customer(
            id: widget.existingCustomer?.id ?? Uuid().v4(),
            name: _nameController.text,
            dateOfBirth: _dateOfBirth,
            phoneNumber: _phoneController.text,
            gender: _gender,
            weight: weight,
            trainingType: _trainingType,
            startDate: _startDate,
            endDate: _endDate,
            fees: fees,
            paymentStatus: _paymentStatus,
            paymentType: _paymentType,
            profilePic: _profilePicBase64,
          );

          await ref.read(firebaseServiceProvider).addCustomer(customer);
        }

        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(e.toString());
        print('Error submitting form: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Color(0xFF1A1A2E),
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 70),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isRenewal
                    ? 'Membership Renewed Successfully!'
                    : 'Member Added Successfully!',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                widget.isRenewal
                    ? 'The membership has been renewed successfully.'
                    : 'New member has been added to the system.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!widget.isRenewal) {
                _nameController.clear();
                _phoneController.clear();
                _weightController.clear();
                _feesController.clear();
                setState(() {
                  _gender = 'Male';
                  _trainingType = 'General';
                  _paymentStatus = 'Paid';
                  _paymentType = 'CASH';
                  _profilePicBase64 = null;
                  _dateOfBirth =
                      DateTime.now().subtract(Duration(days: 365 * 18));
                  _startDate = DateTime(2025, 1, 1);
                  _endDate = DateTime.now().add(Duration(days: 30));
                });
              } else {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFB388FF),
            ),
            child: Text(
              widget.isRenewal ? 'Go Back' : 'OK Done',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Color(0xFF1A1A2E),
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: Colors.red, size: 70),
              ),
              SizedBox(height: 24),
              Text(
                'Something Went Wrong',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFB388FF),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SafeArea(child: _buildCustomAppBar(context)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Member Information',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: Duration(milliseconds: 400)),
                      SizedBox(height: 20),
                      Column(
                        children: [
                          Text(
                            'Profile Picture',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF8E2DE2).withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFFB388FF).withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _profilePicBase64 != null
                                ? GestureDetector(
                                    onTap: () {
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
                                                  tag: 'profile-pic',
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
                                    },
                                    child: Hero(
                                      tag: 'profile-pic',
                                      child: ClipOval(
                                        child: Image.memory(
                                          base64Decode(_profilePicBase64!),
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                        ),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: Icon(
                                  Icons.photo_library,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Color(0xFF8E2DE2).withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Color(0xFF8E2DE2).withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              if (_profilePicBase64 != null) ...[
                                SizedBox(width: 10),
                                IconButton(
                                  onPressed: _removeProfilePic,
                                  icon: Icon(Icons.delete,
                                      color: Color(0xFFE94560)),
                                  tooltip: 'Remove Picture',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 100)),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        hintText: 'Enter member\'s full name',
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 200)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _weightController,
                              label: 'Weight (kg)',
                              icon: Icons.fitness_center,
                              hintText: 'Enter weight in kg',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 300)),
                      SizedBox(height: 16),
                      _buildDatePicker(
                        label: 'Date of Birth',
                        icon: Icons.cake,
                        selectedDate: _dateOfBirth,
                        onDateSelected: (date) =>
                            setState(() => _dateOfBirth = date),
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 400)),
                      SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Gender',
                        icon: Icons.wc,
                        items: [
                          'Male',
                          'Female',
                        ],
                        value: _gender,
                        onChanged: (value) => setState(() => _gender = value!),
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 500)),
                      SizedBox(height: 24),
                      Text(
                        'Membership Details',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 600)),
                      SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Training Type',
                        icon: Icons.fitness_center,
                        items: ['General', 'Personal'],
                        value: _trainingType,
                        onChanged: (value) =>
                            setState(() => _trainingType = value!),
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 700)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _feesController,
                              label: 'Fees',
                              icon: Icons.attach_money,
                              hintText: 'Amount',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Payment Status',
                              icon: Icons.payment,
                              items: ['Paid', 'Pending'],
                              value: _paymentStatus,
                              onChanged: (value) =>
                                  setState(() => _paymentStatus = value!),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 700)),
                      SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Payment Type',
                        icon: Icons.money,
                        items: ['CASH', 'GPAY', 'PHONEPE', 'PAYTM'],
                        value: _paymentType,
                        onChanged: (value) =>
                            setState(() => _paymentType = value!),
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 750)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              label: 'Start Date',
                              icon: Icons.calendar_today,
                              selectedDate: _startDate,
                              onDateSelected: (date) =>
                                  setState(() => _startDate = date),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDatePicker(
                              label: 'End Date',
                              icon: Icons.event_available,
                              selectedDate: _endDate,
                              onDateSelected: (date) =>
                                  setState(() => _endDate = date),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 800)),
                      SizedBox(height: 40),
                      _buildSubmitButton().animate().fadeIn(
                          duration: Duration(milliseconds: 600),
                          delay: Duration(milliseconds: 1000)),
                      SizedBox(height: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFB388FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Color(0xFFB388FF).withOpacity(0.7)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (keyboardType == TextInputType.number) {
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            if (double.parse(value) <= 0) {
              return 'Please enter a number greater than 0';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFB388FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Color(0xFF1A1A2E),
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Color(0xFFB388FF).withOpacity(0.7)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFFB388FF)),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final DateTime firstDate;
          final DateTime lastDate;

          if (label == 'Date of Birth') {
            firstDate = DateTime(1900);
            lastDate = DateTime.now();
          } else {
            firstDate = DateTime(2000);
            lastDate = DateTime(2100);
          }

          final DateTime initialDate = label == 'Date of Birth'
              ? selectedDate
              : selectedDate.isBefore(firstDate)
                  ? firstDate
                  : selectedDate.isAfter(lastDate)
                      ? lastDate
                      : selectedDate;

          final date = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Color(0xFF8E2DE2),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1A1A2E),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: Color(0xFF1A1A2E),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFB388FF),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) onDateSelected(date);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Color(0xFFB388FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFFB388FF).withOpacity(0.7)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(selectedDate),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Color(0xFFB388FF).withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFF8E2DE2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 5,
          shadowColor: Color(0xFF8E2DE2).withOpacity(0.5),
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
                    widget.isRenewal ? Icons.refresh_rounded : Icons.save,
                    size: 22,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.isRenewal ? 'Renew Membership' : 'Add Member',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isRenewal ? 'Renew Membership' : 'Add New Member',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.isRenewal
                        ? 'Renew an existing membership'
                        : 'Create a new membership',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isRenewal ? Icons.refresh : Icons.person_add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 400))
        .slideY(begin: -0.2, end: 0);
  }
}
