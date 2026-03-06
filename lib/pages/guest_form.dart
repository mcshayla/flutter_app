import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';

class GuestForm extends StatefulWidget {
  final Map<String, dynamic>? existingGuest;

  const GuestForm({this.existingGuest, super.key});

  @override
  State<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends State<GuestForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _groupController = TextEditingController();
  final _plusOneNameController = TextEditingController();
  final _mealController = TextEditingController();
  final _dietaryController = TextEditingController();
  final _notesController = TextEditingController();
  String _rsvpStatus = 'not_sent';
  bool _plusOneAllowed = false;

  bool get _isEditing => widget.existingGuest != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final g = widget.existingGuest!;
      _firstNameController.text = g['first_name'] ?? '';
      _lastNameController.text = g['last_name'] ?? '';
      _emailController.text = g['email'] ?? '';
      _phoneController.text = g['phone'] ?? '';
      _groupController.text = g['group_name'] ?? '';
      _plusOneNameController.text = g['plus_one_name'] ?? '';
      _mealController.text = g['meal_preference'] ?? '';
      _dietaryController.text = g['dietary_restrictions'] ?? '';
      _notesController.text = g['notes'] ?? '';
      _rsvpStatus = g['rsvp_status'] ?? 'not_sent';
      _plusOneAllowed = g['plus_one_allowed'] == true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _groupController.dispose();
    _plusOneNameController.dispose();
    _mealController.dispose();
    _dietaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF7B3F61)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7B3F61), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B3F61)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Guest' : 'Add Guest',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                appState.deleteGuest(widget.existingGuest!['id']);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        decoration: _inputDecoration('First Name'),
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        decoration: _inputDecoration('Last Name'),
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Phone'),
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _groupController,
                  decoration: _inputDecoration('Group (e.g. Bride\'s Family)'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _rsvpStatus,
                  decoration: _inputDecoration('RSVP Status'),
                  items: const [
                    DropdownMenuItem(value: 'not_sent', child: Text('Not Sent')),
                    DropdownMenuItem(value: 'invited', child: Text('Invited')),
                    DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                    DropdownMenuItem(value: 'declined', child: Text('Declined')),
                    DropdownMenuItem(value: 'maybe', child: Text('Maybe')),
                  ],
                  onChanged: (v) => setState(() => _rsvpStatus = v ?? 'not_sent'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _mealController,
                  decoration: _inputDecoration('Meal Preference'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _dietaryController,
                  decoration: _inputDecoration('Dietary Restrictions'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: Text('Plus One', style: GoogleFonts.montserrat(fontSize: 14)),
                  value: _plusOneAllowed,
                  onChanged: (v) => setState(() => _plusOneAllowed = v),
                  activeColor: const Color(0xFF7B3F61),
                  contentPadding: EdgeInsets.zero,
                ),

                if (_plusOneAllowed) ...[
                  TextField(
                    controller: _plusOneNameController,
                    decoration: _inputDecoration('Plus One Name'),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _notesController,
                  decoration: _inputDecoration('Notes'),
                  maxLines: 3,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isEditing ? 'Update Guest' : 'Add Guest',
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a first name')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final guestData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'group_name': _groupController.text.trim(),
      'rsvp_status': _rsvpStatus,
      'meal_preference': _mealController.text.trim(),
      'dietary_restrictions': _dietaryController.text.trim(),
      'plus_one_allowed': _plusOneAllowed,
      'plus_one_name': _plusOneNameController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    if (_isEditing) {
      appState.updateGuest(widget.existingGuest!['id'], guestData);
    } else {
      appState.addGuest(guestData);
    }

    Navigator.pop(context);
  }
}
