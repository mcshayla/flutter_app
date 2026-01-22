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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Photo management
  List<XFile> _selectedImages = [];
  List<String> _uploadedImageUrls = [];

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      'contact_email': _emailController.text.trim(),
      'contact_phone': _phoneController.text.trim(),
      'vendor_user_id': widget.userId,
      'is_claimed': true,
      'claimed_at': DateTime.now().toIso8601String(),
    }).select().single();

    List<String> imageUrls = [];
    if (_selectedImages.isNotEmpty) {
      imageUrls = await _uploadImages(businessName);
      
      // Update vendor with image URLs
      await supabase.from('vendors').update({
        'image_url': imageUrls,
      }).eq('vendor_id', vendorResponse['vendor_id']);
    }

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
              'Fill in the basic information to get started',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF6E6E6E),
              ),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name *',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF7B3F61),
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
              style: GoogleFonts.montserrat(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description *',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF7B3F61),
                ),
                hintText: 'Describe your business and services',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 12,
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
              style: GoogleFonts.montserrat(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category *',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF7B3F61),
                ),
                hintText: 'e.g., Photographer, Venue, Florist',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 12,
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
              style: GoogleFonts.montserrat(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location *',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF7B3F61),
                ),
                hintText: 'City, State',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 12,
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
              style: GoogleFonts.montserrat(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email *',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF7B3F61),
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
              style: GoogleFonts.montserrat(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF7B3F61),
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
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Photo Upload Section
            Text(
              'Photos',
              style: GoogleFonts.bodoniModa(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
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
                      kIsWeb
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
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
            const SizedBox(height: 16),
            Text(
              'You can add more details later in your dashboard',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF6E6E6E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}