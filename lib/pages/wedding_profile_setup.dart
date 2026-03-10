import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import '../widgets/category_selection_sheet.dart';

class WeddingProfileSetup extends StatefulWidget {
  final Map<String, dynamic>? existingProfile;

  const WeddingProfileSetup({this.existingProfile, super.key});

  @override
  State<WeddingProfileSetup> createState() => _WeddingProfileSetupState();
}

class _WeddingProfileSetupState extends State<WeddingProfileSetup> {
  final _partner1Controller = TextEditingController();
  final _partner2Controller = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _weddingDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _partner1Controller.text = widget.existingProfile!['partner_name_1'] ?? '';
      _partner2Controller.text = widget.existingProfile!['partner_name_2'] ?? '';
      _locationController.text = widget.existingProfile!['wedding_location'] ?? '';
      if (widget.existingProfile!['wedding_date'] != null) {
        _weddingDate = DateTime.tryParse(widget.existingProfile!['wedding_date']);
      }
    }
  }

  @override
  void dispose() {
    _partner1Controller.dispose();
    _partner2Controller.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7B3F61),
              onPrimary: Colors.white,
              surface: Color(0xFFF8F5F0),
              onSurface: Color(0xFF3E3E3E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _weddingDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (_partner1Controller.text.trim().isEmpty || _partner2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both partner names')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profileData = {
        'user_id': user.id,
        'partner_name_1': _partner1Controller.text.trim(),
        'partner_name_2': _partner2Controller.text.trim(),
        'wedding_location': _locationController.text.trim(),
        'wedding_date': _weddingDate?.toIso8601String().split('T')[0],
      };

      await Supabase.instance.client
          .from('wedding_profiles')
          .upsert(profileData, onConflict: 'user_id');

      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadWeddingProfile();

      // If we have a wedding date and no existing checklist, show category selection
      if (_weddingDate != null && appState.checklistItems.isEmpty) {
        if (!mounted) return;
        final categories = await showCategorySelectionSheet(context, categories: appState.categoryNames);
        if (categories != null && categories.isNotEmpty) {
          await appState.initializeChecklistWithCategories(_weddingDate!, categories);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(
        fontSize: 13,
        color: const Color(0xFF7B3F61),
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Your Wedding',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about your big day',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B3F61),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us personalize your planning experience',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: const Color(0xFF6E6E6E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _partner1Controller,
                  decoration: _inputDecoration('Partner 1 Name'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _partner2Controller,
                  decoration: _inputDecoration('Partner 2 Name'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _locationController,
                  decoration: _inputDecoration('Wedding Location (City, State)'),
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCC7AA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF7B3F61), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _weddingDate != null
                              ? '${_weddingDate!.month}/${_weddingDate!.day}/${_weddingDate!.year}'
                              : 'Select Wedding Date',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: _weddingDate != null
                                ? const Color(0xFF3E3E3E)
                                : const Color(0xFF7B3F61),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}
