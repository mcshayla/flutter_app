// vendor_edit_profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:provider/provider.dart';
import '../utils/image_compress.dart';
import '../appstate.dart';
import 'location_picker_page.dart';

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
  final _picker = ImagePicker();
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
  late TextEditingController _guestCapacityController;

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

  // Location picker
  double? _pickedLat;
  double? _pickedLng;
  String _pickedAddress = '';

  // Photo management
  List<String> existingImageUrls = [];
  List<XFile> newImages = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSocialMediaLinks();
    _loadStateAndCounty();
    _loadExistingImages();
  }

  void _initializeControllers() {
    // Load stored coordinates
    _pickedLat = (widget.vendorData['latitude'] as num?)?.toDouble();
    _pickedLng = (widget.vendorData['longitude'] as num?)?.toDouble();
    if (_pickedLat != null && _pickedLng != null) {
      _pickedAddress = (widget.vendorData['address'] as String?) ?? '';
    }

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
    _guestCapacityController = TextEditingController(text: widget.vendorData['guest_capacity']);

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
      Map<String, List<String>> socialMediaUrls = {
        'facebook': [],
        'instagram': [],
        'twitter': [],
        'linkedin': [],
        'pinterest': [],
        'youtube': [],
        'tiktok': [],
      };
      
      for (var link in links) {
        final url = link.toString().toLowerCase();
        if (url.contains('facebook')) {
          socialMediaUrls['facebook']!.add(link.toString());
        } else if (url.contains('instagram')) {
          socialMediaUrls['instagram']!.add(link.toString());
        } else if (url.contains('twitter')) {
          socialMediaUrls['twitter']!.add(link.toString());
        } else if (url.contains('linkedin')) {
          socialMediaUrls['linkedin']!.add(link.toString());
        } else if (url.contains('pinterest')) {
          socialMediaUrls['pinterest']!.add(link.toString());
        } else if (url.contains('youtube')) {
          socialMediaUrls['youtube']!.add(link.toString());
        } else if (url.contains('tiktok')) {
          socialMediaUrls['tiktok']!.add(link.toString());
        }
      }
      
      _facebookController.text = socialMediaUrls['facebook']!.join(', ');
      _instagramController.text = socialMediaUrls['instagram']!.join(', ');
      _twitterController.text = socialMediaUrls['twitter']!.join(', ');
      _linkedinController.text = socialMediaUrls['linkedin']!.join(', ');
      _pinterestController.text = socialMediaUrls['pinterest']!.join(', ');
      _youtubeController.text = socialMediaUrls['youtube']!.join(', ');
      _tiktokController.text = socialMediaUrls['tiktok']!.join(', ');
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

  void _loadExistingImages() {
    final images = widget.vendorData['image_url'];
    if (images is List) {
      existingImageUrls = images.map((e) => e.toString()).toList();
    } else if (images != null && images.toString().isNotEmpty) {
      existingImageUrls = [images.toString()];
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
    _guestCapacityController.dispose();
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
    final limit = context.read<AppState>().vendorPhotoLimit;
    final totalExisting = existingImageUrls.length + newImages.length;
    final remaining = limit - totalExisting;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $limit photos allowed')),
      );
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          newImages.addAll(images.take(remaining));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
  }

  Future<void> _removeExistingImage(int index) async {
    final imageUrl = existingImageUrls[index];
    
    // Extract the file path from the URL
    // Format: https://[project].supabase.co/storage/v1/object/public/vendor-photos/VendorName/filename.jpg
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    
    // Find the index where 'vendor-photos' appears and get everything after it
    final bucketIndex = pathSegments.indexOf('vendor-photos');
    if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      try {
        await supabase.storage.from('vendor-photos').remove([filePath]);
        
        setState(() {
          existingImageUrls.removeAt(index);
        });

         await supabase
          .from('vendors')
          .update({
            'image_url': existingImageUrls,
          })
          .eq('vendor_id', widget.vendorData['vendor_id']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image deleted',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF7B3F61),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _collectSocialMediaLinks() {
    List<String> links = [];
    
    void addLinks(String text) {
      final urls = text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      links.addAll(urls);
    }
    
    addLinks(_facebookController.text);
    addLinks(_instagramController.text);
    addLinks(_twitterController.text);
    addLinks(_linkedinController.text);
    addLinks(_pinterestController.text);
    addLinks(_youtubeController.text);
    addLinks(_tiktokController.text);
    
    return links;
  }

  Future<List<String>> _uploadNewImages(String vendorName) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < newImages.length; i++) {
      final image = newImages[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final filePath = '$vendorName/$fileName';

      try {
        final rawBytes = await image.readAsBytes();
        final bytes = await compressForUpload(rawBytes);

        await supabase.storage
            .from('vendor-photos')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final vendorName = _nameController.text.trim();
      
      // Upload new images
      List<String> newImageUrls = [];
      if (newImages.isNotEmpty) {
        newImageUrls = await _uploadNewImages(vendorName);
      }
      
      // Combine existing and new image URLs
      final allImageUrls = [...existingImageUrls, ...newImageUrls];

      final updates = <String, dynamic>{
        'vendor_name': vendorName,
        'vendor_description': _descriptionController.text.trim(),
        'vendor_location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'vendor_price': _priceController.text.trim(),
        'vendor_estimated_price': _estimatedPriceController.text.trim(),
        'guest_capacity': _guestCapacityController.text.trim(),
        'contact_email': _emailController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'website_url': _websiteController.text.trim(),
        'style_keywords': _styleKeywordsController.text.trim(),
        'social_media_links': _collectSocialMediaLinks(),
        'vendor_state': selectedStates,
        'vendor_county': selectedCounties,
        'image_url': allImageUrls,
      };
      if (_pickedLat != null) updates['latitude'] = _pickedLat;
      if (_pickedLng != null) updates['longitude'] = _pickedLng;

      await supabase
          .from('vendors')
          .update(updates)
          .eq('vendor_id', widget.vendorData['vendor_id'])
          .select();

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
        Navigator.pop(context, true);
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
        backgroundColor: Colors.transparent,
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
            const SizedBox(height: 12),
            _buildLocationPickerTile(),
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
            const SizedBox(height: 16),
            _buildTextField(
              controller: _guestCapacityController,
              label: 'Guest Capacity',
              hint: 'e.g., 50 - 300',
              keyboardType: TextInputType.text,
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
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.facebook,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _instagramController,
              label: 'Instagram URL',
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.camera_alt,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _twitterController,
              label: 'Twitter URL',
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.tag,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _linkedinController,
              label: 'LinkedIn URL',
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.business,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pinterestController,
              label: 'Pinterest URL',
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.push_pin,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _youtubeController,
              label: 'YouTube URL',
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.play_circle,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _tiktokController,
              label: 'TikTok URL',
              hint: 'Multiple URLs separated by comma',
              keyboardType: TextInputType.url,
              prefixIcon: Icons.music_note,
            ),
            const SizedBox(height: 32),

            // Photos Section
            _buildSectionHeader('Photos'),
            const SizedBox(height: 16),
            
            // Existing Photos
            if (existingImageUrls.isNotEmpty) ...[
              Text(
                'Current Photos',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: existingImageUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          existingImageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeExistingImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
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
              const SizedBox(height: 16),
            ],

            // Add New Photos Button
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                'Add More Photos',
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B3F61),
                side: const BorderSide(color: Color(0xFFDCC7AA)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // New Photos Preview
            if (newImages.isNotEmpty) ...[
              Text(
                'New Photos to Upload',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: newImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                newImages[index].path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(newImages[index].path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeNewImage(index),
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
              const SizedBox(height: 16),
            ],

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

  Widget _buildLocationPickerTile() {
    final hasLocation = _pickedLat != null && _pickedLng != null;
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<LocationResult>(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerPage(
              initialLat: _pickedLat,
              initialLng: _pickedLng,
            ),
          ),
        );
        if (result != null && mounted) {
          setState(() {
            _pickedLat = result.latitude;
            _pickedLng = result.longitude;
            _pickedAddress = result.address;
            if (_addressController.text.trim().isEmpty) {
              _addressController.text = result.address;
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasLocation
                ? const Color(0xFF7B3F61)
                : const Color(0xFFDCC7AA),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: hasLocation
                  ? const Color(0xFF7B3F61)
                  : const Color(0xFF6E6E6E),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasLocation
                    ? _pickedAddress.isNotEmpty
                        ? _pickedAddress
                        : '${_pickedLat!.toStringAsFixed(5)}, ${_pickedLng!.toStringAsFixed(5)}'
                    : 'Set exact location on map',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: hasLocation
                      ? const Color(0xFF3E3E3E)
                      : const Color(0xFF6E6E6E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              hasLocation ? 'Change' : 'Pick',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF7B3F61),
                fontWeight: FontWeight.w600,
              ),
            ),
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