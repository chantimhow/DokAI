import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatting (numbers only)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE VARIABLES ---
  String _name = "Not set";
  String _age = "Not set";
  String _bloodType = "Not set";
  String _allergies = "None";
  String _emergencyContact = "Not set";
  String _medicalConditions = "None";

  // --- REUSABLE DIALOG WITH VALIDATION ---
  Future<void> _showEditDialog(String title, String currentValue, Function(String) onSave) async {
    final formKey = GlobalKey<FormState>();
    
    TextEditingController controller = TextEditingController(
      text: (currentValue == "Not set" || currentValue == "None") ? "" : currentValue,
    );

    // Pre-defined blood types for the dropdown
    final List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];
    String selectedBlood = bloodTypes.contains(currentValue) ? currentValue : 'A+';

    return showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder allows the dialog to update its own state (like dropdown selection)
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Edit $title",
                style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: title == "Blood Type"
                    // --- DROPDOWN FOR BLOOD TYPE ---
                    ? DropdownButtonFormField<String>(
                        value: selectedBlood,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF009688), width: 2),
                          ),
                        ),
                        items: bloodTypes.map((String type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => selectedBlood = newValue);
                          }
                        },
                      )
                    // --- TEXT FIELD FOR EVERYTHING ELSE ---
                    : TextFormField(
                        controller: controller,
                        textCapitalization: TextCapitalization.words,
                        // If it's Age or Phone, show the number keyboard
                        keyboardType: (title == "Age" || title == "Emergency Contact") 
                            ? TextInputType.number 
                            : TextInputType.text,
                        // Force only numbers for age
                        inputFormatters: title == "Age" 
                            ? [FilteringTextInputFormatter.digitsOnly] 
                            : null,
                        decoration: InputDecoration(
                          hintText: "Enter $title",
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF009688), width: 2),
                          ),
                        ),
                        autofocus: true,
                        // --- THE DATA VALIDATOR ---
                        validator: (value) {
                          if (title == "Age") {
                            if (value == null || value.isEmpty) return 'Age is required';
                            int? ageVal = int.tryParse(value);
                            if (ageVal == null || ageVal < 0 || ageVal > 99) {
                              return 'Please enter a valid age (0-99)';
                            }
                          }
                          if (title == "Name") {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name cannot be empty';
                            }
                          }
                          return null;
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Check if the validation rules pass before saving!
                    if (formKey.currentState!.validate()) {
                      if (title == "Blood Type") {
                        onSave(selectedBlood);
                      } else {
                        onSave(controller.text.trim());
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9F9), 
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 35.0),
          physics: const BouncingScrollPhysics(),
          children: [
            
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF009688).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: 55,
                        color: Color(0xFF009688), 
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Text(
                  "Medical ID",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00695C), 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- EDITABLE DATA FIELDS ---
            _buildEditCard("Name", _name, () {
              _showEditDialog("Name", _name, (newValue) => setState(() => _name = newValue));
            }),
            
            _buildEditCard("Age", _age, () {
              _showEditDialog("Age", _age, (newValue) => setState(() => _age = newValue));
            }),
            
            _buildEditCard("Blood Type", _bloodType, () {
              _showEditDialog("Blood Type", _bloodType, (newValue) => setState(() => _bloodType = newValue));
            }),
            
            _buildEditCard("Allergies", _allergies, () {
              _showEditDialog("Allergies", _allergies, (newValue) => setState(() => _allergies = newValue));
            }),
            
            _buildEditCard("Emergency Contact", _emergencyContact, () {
              _showEditDialog("Emergency Contact", _emergencyContact, (newValue) => setState(() => _emergencyContact = newValue));
            }),
            
            _buildEditCard("Medical Conditions", _medicalConditions, () {
              _showEditDialog("Medical Conditions", _medicalConditions, (newValue) => setState(() => _medicalConditions = newValue));
            }),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medical ID Updated Successfully!'),
                    backgroundColor: Color(0xFF009688),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F), 
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: const Color(0xFF00838F).withOpacity(0.5),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Update Info",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(String title, String value, VoidCallback onEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, color: Color(0xFF009688), size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Edit",
                      style: TextStyle(
                        color: Color(0xFF009688),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}