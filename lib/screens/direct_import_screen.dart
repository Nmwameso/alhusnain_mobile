import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

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
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _fullNameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must accept the Terms and Conditions to proceed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        setState(() {
          _agreeToTerms = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      print('Submission error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(
            'Thank you for choosing our Direct Import service. To ensure a smooth and transparent process, please review the following terms:\n\n'
                '1. **Car Search & Purchase:** Our team is committed to assisting you in finding a suitable vehicle based on the specifications you provide.\n\n'
                '2. **Cost Notification:** Once we identify a suitable car, we will provide you with a detailed cost breakdown, including the purchase price, shipping fees, and any other necessary charges.\n\n'
                '3. **Payment Terms:** To initiate the purchase, we kindly ask for an upfront payment of 50% of the total cost. The remaining balance will be due upon the vehicle’s arrival at the designated port.\n\n'
                '4. **Shipping & Delivery:** Estimated shipping times may vary due to logistics, customs clearance, or other unforeseen factors. While we strive to ensure timely delivery, we are not responsible for delays caused by third-party shipping providers or customs procedures.\n\n'
                '5. **Customs & Import Duties:** Any applicable import duties, taxes, and clearance fees required by your home country’s regulations will be the client’s responsibility. We are happy to guide you through this process if needed.\n\n'
                '6. **Cancellation & Refund Policy:** Once the initial 50% payment has been made and the purchase is confirmed, cancellations may not be eligible for a full refund. Refunds, if applicable, will be subject to deductions for administrative and cancellation costs.\n\n'
                '7. **Vehicle Condition & Warranty:** We take great care to ensure that the vehicle matches the stated condition before shipment. However, any warranties provided will be as per the seller or manufacturer’s terms.\n\n'
                'By clicking "Accept," you confirm that you have read, understood, and agreed to these terms and conditions.\n\n'
                'If you have any questions, please feel free to reach out—we’re happy to assist you!',
            style: TextStyle(fontSize: 14),
          ),

        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _agreeToTerms = true;
              });
              Navigator.pop(context);
            },
            child: Text('Accept', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
              _buildTextField(_fullNameController, 'Full Name', 'Enter your full name', isReadOnly: true),
              _buildTextField(
                _phoneController,
                'Phone Number',
                'Enter your phone number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  final phoneRegex = RegExp(r'^\+?[0-9]{8,}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              _buildTextField(_emailController, 'Email Address', 'Enter your email', isReadOnly: true),
              _buildTextField(_makeController, 'Car Make', 'Enter car make'),
              _buildTextField(_modelController, 'Car Model', 'Enter car model'),
              _buildTextField(_featuresController, 'Extra information', 'Describe car extra information', maxLines: 3),
              SizedBox(height: 20),

              // Terms & Conditions Checkbox (disabled until accepted)
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: null, // Prevent manual checking
                  ),
                  GestureDetector(
                    onTap: _showTermsDialog,
                    child: Text(
                      'I agree to the terms and conditions',
                      style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting || !_agreeToTerms ? null : _handleSubmit,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String hint, {
        bool isEmail = false,
        int maxLines = 1,
        bool requiredField = true,
        bool isReadOnly = false,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? (isEmail ? TextInputType.emailAddress : TextInputType.text),
        maxLines: maxLines,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
