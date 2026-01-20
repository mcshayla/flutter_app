// vendor_edit_profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VendorEditProfile extends StatefulWidget {
  final Map<String, dynamic> vendorData;

  const VendorEditProfile({
    required this.vendorData,
    super.key,
  });

  @override
  State<VendorEditProfile> createState() => _VendorEditProfileState();
}

class _VendorEditProfileState extends State<VendorEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _estimatedPriceController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _styleKeywordsController;

  // Social media controllers
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _linkedinController;
  late TextEditingController _pinterestController;
  late TextEditingController _youtubeController;
  late TextEditingController _tiktokController;

  // State and County
  List<String> selectedStates = [];
  List<String> selectedCounties = [];
  final List<String> availableStates = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming', 'Any'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSocialMediaLinks();
    _loadStateAndCounty();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.vendorData['vendor_name']);
    _descriptionController = TextEditingController(text: widget.vendorData['vendor_description']);
    _locationController = TextEditingController(text: widget.vendorData['vendor_location']);
    _addressController = TextEditingController(text: widget.vendorData['address']);
    _priceController = TextEditingController(text: widget.vendorData['vendor_price']);
    _estimatedPriceController = TextEditingController(text: widget.vendorData['vendor_estimated_price']);
    _emailController = TextEditingController(text: widget.vendorData['contact_email']);
    _phoneController = TextEditingController(text: widget.vendorData['contact_phone']);
    _websiteController = TextEditingController(text: widget.vendorData['website_url']);
    _styleKeywordsController = TextEditingController(text: widget.vendorData['style_keywords']);

    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _twitterController = TextEditingController();
    _linkedinController = TextEditingController();
    _pinterestController = TextEditingController();
    _youtubeController = TextEditingController();
    _tiktokController = TextEditingController();
  }

  void _loadSocialMediaLinks() {
    final links = widget.vendorData['social_media_links'] as List<dynamic>?;
    if (links != null) {
      for (var link in links) {
        final url = link.toString().toLowerCase();
        if (url.contains('facebook')) {
          _facebookController.text = link.toString();
        } else if (url.contains('instagram')) {
          _instagramController.text = link.toString();
        } else if (url.contains('twitter')) {
          _twitterController.text = link.toString();
        } else if (url.contains('linkedin')) {
          _linkedinController.text = link.toString();
        } else if (url.contains('pinterest')) {
          _pinterestController.text = link.toString();
        } else if (url.contains('youtube')) {
          _youtubeController.text = link.toString();
        } else if (url.contains('tiktok')) {
          _tiktokController.text = link.toString();
        }
      }
    }
  }

  void _loadStateAndCounty() {
    // Load states
    final states = widget.vendorData['vendor_state'];
    if (states is List) {
      selectedStates = states.map((e) => e.toString()).toList();
    } else if (states != null && states.toString().isNotEmpty) {
      selectedStates = [states.toString()];
    }

    // Load counties
    final counties = widget.vendorData['vendor_county'];
    if (counties is List) {
      selectedCounties = counties.map((e) => e.toString()).toList();
    } else if (counties != null && counties.toString().isNotEmpty) {
      selectedCounties = [counties.toString()];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _estimatedPriceController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _styleKeywordsController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _pinterestController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  List<String> _collectSocialMediaLinks() {
    List<String> links = [];
    if (_facebookController.text.trim().isNotEmpty) links.add(_facebookController.text.trim());
    if (_instagramController.text.trim().isNotEmpty) links.add(_instagramController.text.trim());
    if (_twitterController.text.trim().isNotEmpty) links.add(_twitterController.text.trim());
    if (_linkedinController.text.trim().isNotEmpty) links.add(_linkedinController.text.trim());
    if (_pinterestController.text.trim().isNotEmpty) links.add(_pinterestController.text.trim());
    if (_youtubeController.text.trim().isNotEmpty) links.add(_youtubeController.text.trim());
    if (_tiktokController.text.trim().isNotEmpty) links.add(_tiktokController.text.trim());
    return links;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'vendor_name': _nameController.text.trim(),
        'vendor_description': _descriptionController.text.trim(),
        'vendor_location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'vendor_price': _priceController.text.trim(),
        'vendor_estimated_price': _estimatedPriceController.text.trim(),
        'contact_email': _emailController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'website_url': _websiteController.text.trim(),
        'style_keywords': _styleKeywordsController.text.trim(),
        'social_media_links': _collectSocialMediaLinks(),
        'vendor_state': selectedStates,
        'vendor_county': selectedCounties,
      };

      await supabase
          .from('vendors')
          .update(updates)
          .eq('vendor_id', widget.vendorData['vendor_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF7B3F61),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Business Name',
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _styleKeywordsController,
              label: 'Style Keywords (comma-separated)',
              hint: 'e.g., Rustic, Elegant, Modern',
            ),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader('Location'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'City, State',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Full Address',
            ),
            const SizedBox(height: 16),

            // State Selection
            _buildMultiSelectField(
              label: 'States Served',
              items: availableStates,
              selectedItems: selectedStates,
              onChanged: (values) {
                setState(() {
                  selectedStates = values;
                });
              },
            ),
            const SizedBox(height: 16),

            // County Input (free text since counties vary by state)
            _buildTextField(
              controller: TextEditingController(
                text: selectedCounties.join(', '),
              ),
              label: 'Counties Served (comma-separated)',
              hint: 'e.g., Salt Lake, Utah, Davis, or "Any"',
              onChanged: (value) {
                selectedCounties = value
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              },
            ),
            const SizedBox(height: 24),

            // Pricing Section
            _buildSectionHeader('Pricing'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Price',
              hint: 'e.g., \$500 - \$2000',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _estimatedPriceController,
              label: 'Estimated Price Range',
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            _buildSectionHeader('Contact Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Social Media Section
            _buildSectionHeader('Social Media'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _facebookController,
              label: 'Facebook URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.facebook,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _instagramController,
              label: 'Instagram URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.camera_alt,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _twitterController,
              label: 'Twitter URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.tag,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _linkedinController,
              label: 'LinkedIn URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.business,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pinterestController,
              label: 'Pinterest URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.push_pin,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _youtubeController,
              label: 'YouTube URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.play_circle,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _tiktokController,
              label: 'TikTok URL',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.music_note,
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B3F61),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.bodoniModa(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF7B3F61),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          color: const Color(0xFF7B3F61),
        ),
        hintStyle: GoogleFonts.montserrat(
          fontSize: 11,
          color: const Color(0xFF6E6E6E).withOpacity(0.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7B3F61)),
        ),
      ),
      style: GoogleFonts.montserrat(fontSize: 12),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7B3F61),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDCC7AA)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(
                  item,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: isSelected ? Colors.white : const Color(0xFF7B3F61),
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  final newSelection = List<String>.from(selectedItems);
                  if (selected) {
                    newSelection.add(item);
                  } else {
                    newSelection.remove(item);
                  }
                  onChanged(newSelection);
                },
                selectedColor: const Color(0xFF7B3F61),
                backgroundColor: const Color(0xFFDCC7AA).withOpacity(0.2),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF7B3F61)
                      : const Color(0xFFDCC7AA),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}