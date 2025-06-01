import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';

class EditStationScreen extends StatefulWidget {
  final String stationId;
  final Map<String, dynamic> stationData;

  EditStationScreen({
    required this.stationId,
    required this.stationData,
  });

  @override
  _EditStationScreenState createState() => _EditStationScreenState();
}

class _EditStationScreenState extends State<EditStationScreen> {
  late TextEditingController nameController;
  late TextEditingController hoursController;
  late TextEditingController contactController;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.stationData['name'] ?? '');
    hoursController =
        TextEditingController(text: widget.stationData['hours'] ?? '');
    contactController =
        TextEditingController(text: widget.stationData['contact'] ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    hoursController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('refill_stations')
          .doc(widget.stationId)
          .update({
        'name': nameController.text.trim(),
        'hours': hoursController.text.trim(),
        'contact': contactController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context, true); // Return true to indicate successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update station details'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Edit Station Details',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Station Name',
                        icon: Icons.store,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter station name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: hoursController,
                        label: 'Operating Hours',
                        icon: Icons.access_time,
                        hint: 'e.g. 8:00 AM - 5:00 PM',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter operating hours';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: contactController,
                        label: 'Contact Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contact number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: Icon(Icons.save, color: Colors.white),
                        label: Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
