import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:v_shape_app/providers/customer_provider.dart';
import '../models/plan.dart';
import '../services/firebase_service.dart';
import '../widgets/shimmer_loading.dart';

final plansProvider = StreamProvider<List<Plan>>((ref) {
  return ref.read(firebaseServiceProvider).getPlans();
});

class PlansScreen extends ConsumerStatefulWidget {
  @override
  _PlansScreenState createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  Plan? _editingPlan;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final plan = Plan(
        id: _editingPlan?.id ?? Uuid().v4(),
        name: _nameController.text,
        duration: int.parse(_durationController.text),
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
      );

      try {
        if (_editingPlan != null) {
          await ref.read(firebaseServiceProvider).updatePlan(plan);
        } else {
          await ref.read(firebaseServiceProvider).addPlan(plan);
        }

        if (mounted) {
          Navigator.pop(context);
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_editingPlan != null
                  ? 'Plan updated successfully'
                  : 'Plan added successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Color(0xFF2C3E50),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C3E50),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Plan',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Are you sure you want to delete this plan?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE94560),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(firebaseServiceProvider).deletePlan(planId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Plan deleted successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Color(0xFF06BEB6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(20),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete plan: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Color(0xFFE94560),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(20),
            ),
          );
        }
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _durationController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _editingPlan = null;
  }

  void _editPlan(Plan plan) {
    _editingPlan = plan;
    _nameController.text = plan.name;
    _durationController.text = plan.duration.toString();
    _descriptionController.text = plan.description;
    _priceController.text = plan.price.toString();
    _showPlanDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Membership Plans',
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
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
              ),
            ),
            child: _buildContent(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showPlanDialog(context);
        },
        backgroundColor: Color(0xFF8E2DE2),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membership Plans',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          Expanded(child: _buildPlansList()),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    final plansAsync = ref.watch(plansProvider);

    return plansAsync.when(
      data: (plans) => ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildPlanCard(plan);
        },
      ),
      loading: () => ShimmerLoading(),
      error: (error, stack) => Center(
        child: Text(
          'Error loading plans',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.1),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              plan.name,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${plan.duration} Months',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${plan.price}',
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
                SizedBox(width: 8),
                _buildPlanMenu(plan),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features:',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                ...plan.description.split('\n').map((feature) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFFFFB81C),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanMenu(Plan plan) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white70),
      color: Color(0xFF232323),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white24, width: 0.5),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          _editPlan(plan);
        } else if (value == 'delete') {
          _confirmDelete(plan.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF06BEB6), size: 20),
              SizedBox(width: 12),
              Text(
                'Edit Plan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.delete, color: Color(0xFFE94560), size: 20),
              SizedBox(width: 12),
              Text(
                'Delete Plan',
                style: GoogleFonts.poppins(
                  color: Color(0xFFE94560),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlanDialog(BuildContext context) {
    final isEditing = _editingPlan != null;
    final dialogTitle = isEditing ? 'Edit Plan' : 'Add New Plan';
    final actionButtonText = isEditing ? 'Update' : 'Add';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Color(0xFF2C3E50),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogTitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildDialogTextField(
                  controller: _nameController,
                  label: 'Plan Name',
                  icon: Icons.card_membership,
                ),
                SizedBox(height: 16),
                _buildDialogTextField(
                  controller: _durationController,
                  label: 'Duration (months)',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                _buildDialogTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                _buildDialogTextField(
                  controller: _priceController,
                  label: 'Price (₹)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearForm();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFE94560),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8E2DE2),
                      ),
                      child: Text(
                        actionButtonText,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }
}
