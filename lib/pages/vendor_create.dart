// vendor_create.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class VendorCreatePage extends StatefulWidget {
  final String userId;

  const VendorCreatePage({
    required this.userId,
    super.key,
  });

  @override
  State<VendorCreatePage> createState() => _VendorCreatePageState();
}

class _VendorCreatePageState extends State<VendorCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _estimatedPriceController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _styleKeywordsController = TextEditingController();

  // Social media controllers
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _pinterestController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();

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

  // Photo management
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

  Future<List<String>> _uploadImages(String vendorName) async {
    List<String> uploadedUrls = [];
    
    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.${image.path.split('.').last}';
      final filePath = '$vendorName/$fileName';

      try {
        final bytes = await image.readAsBytes();
        
        await supabase.storage
            .from('vendor-photos')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                contentType: 'image/${image.path.split('.').last}',
              ),
            );

        final publicUrl = supabase.storage
            .from('vendor-photos')
            .getPublicUrl(filePath);

        uploadedUrls.add(publicUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return uploadedUrls;
  }

  Future<void> _createVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final businessName = _businessNameController.text.trim();
      
      // Create vendor record FIRST (without images)
      final vendorResponse = await supabase.from('vendors').insert({
        'vendor_name': businessName,
        'vendor_description': _descriptionController.text.trim(),
        'vendor_category': _categoryController.text.trim(),
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
        'vendor_user_id': widget.userId,
        'is_claimed': true,
        'claimed_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Now upload images (vendor record exists, so policy will pass)
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(businessName);
        
        // Update vendor with image URLs
        await supabase.from('vendors').update({
          'image_url': imageUrls,
        }).eq('vendor_id', vendorResponse['vendor_id']);
      }

      // Create vendor profile
      await supabase.from('vendor_profiles').insert({
        'user_id': widget.userId,
        'vendor_id': vendorResponse['vendor_id'],
        'business_name': businessName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vendor profile created successfully!',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF7B3F61),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating vendor: $e'),
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
          'Create Vendor Profile',
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
            Text(
              'Tell us about your business',
              style: GoogleFonts.bodoniModa(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the information to create your vendor profile',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF6E6E6E),
              ),
            ),
            const SizedBox(height: 32),

            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessNameController,
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
              controller: _categoryController,
              label: 'Category',
              hint: 'e.g., Photographer, Venue, Florist',
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
              required: true,
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

            // County Input
            _buildTextField(
              controller: TextEditingController(
                text: selectedCounties.join(', '),
              ),
              label: 'Counties Served (comma-separated)',
              hint: 'e.g., Salt Lake County, Utah County, "Any"',
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
              required: true,
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

            // Photo Upload Section
            _buildSectionHeader('Photos'),
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                'Add Photos',
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B3F61),
                side: const BorderSide(color: Color(0xFFDCC7AA)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImages[index].path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _createVendor,
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
                      'Create Vendor Profile',
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
              if (label == 'Email' && !value.contains('@')) {
                return 'Please enter a valid email';
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