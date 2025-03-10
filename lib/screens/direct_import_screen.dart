import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DirectImportScreen extends StatefulWidget {
  @override
  _DirectImportScreenState createState() => _DirectImportScreenState();
}

class _DirectImportScreenState extends State<DirectImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _featuresController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();
      bool success = await apiService.submitDirectImport(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        emailAddress: _emailController.text,
        make: _makeController.text,
        model: _modelController.text,
        carFeatures: _featuresController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Direct import request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Direct Import Request')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_fullNameController, 'Full Name', 'Enter your full name'),
              _buildTextField(_phoneController, 'Phone Number', 'Enter your phone number'),
              _buildTextField(_emailController, 'Email Address (Optional)', 'Enter your email', isEmail: true),
              _buildTextField(_makeController, 'Car Make', 'Enter car make'),
              _buildTextField(_modelController, 'Car Model', 'Enter car model'),
              _buildTextField(_featuresController, 'Car Features', 'Describe car features', maxLines: 3),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? CircularProgressIndicator()
                    : Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {bool isEmail = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
}
