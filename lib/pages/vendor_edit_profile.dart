// vendor_edit_profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/vendor_filter.dart';
import '../widgets/field_hint.dart';
import '../widgets/vendor_filter_picker.dart';
import '../utils/image_compress.dart';
import '../utils/image_utils.dart';
import '../appstate.dart';
import 'location_picker_page.dart';
import '../utils/regions.dart';

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
  late TextEditingController _startingPriceController;
  late TextEditingController _capacityMinController;
  late TextEditingController _capacityMaxController;
  // vendor_estimated_price is intentionally no longer edited here. It was a
  // third price field that duplicated vendor_price (one vendor had "$1300"
  // against a price of "1000"), and pricing is now one number + one free-text
  // field. The column and its 3 existing rows are left untouched — dropping
  // the key from the save payload means editing a profile cannot blank them.
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

  // Category filter state
  List<Map<String, dynamic>> _categoryFilterDefs = [];
  Map<String, List<String>> _filterValues = {};

  /// filter_options rows keyed by filter_key, for the vendor's category.
  Map<String, List<Map<String, dynamic>>> _filterOptionRows = {};
  bool _filtersLoading = false;

  // State and County
  List<String> selectedStates = [];
  List<String> selectedCounties = [];
  final List<String> availableStates = kUsStates;

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
    _loadCategoryFilters();
  }

  Future<void> _loadCategoryFilters() async {
    final category = widget.vendorData['vendor_category'] as String?;
    if (category == null || category.isEmpty) return;
    setState(() => _filtersLoading = true);
    try {
      // Parse existing filter_values from vendor data
      final raw = widget.vendorData['filter_values'];
      if (raw is Map<String, dynamic>) {
        _filterValues = raw.map((k, v) =>
            MapEntry(k, v is List ? v.map((e) => e.toString()).toList() : []));
      }
      final rows = await supabase
          .from('category_filters')
          .select()
          .eq('category_name', category)
          .order('display_order', ascending: true);
      final defs = (rows as List).cast<Map<String, dynamic>>();

      // Options now live in filter_options; the legacy category_filters.options
      // array is only a fallback for groups that have not been migrated.
      final Map<String, List<Map<String, dynamic>>> optionsByKey = {};
      final keys = defs
          .map((d) => d['filter_key'] as String?)
          .whereType<String>()
          .toList();
      if (keys.isNotEmpty) {
        try {
          final optionRows = await supabase
              .from('filter_options')
              .select()
              .inFilter('filter_key', keys)
              .order('display_order', ascending: true);
          for (final row in optionRows as List) {
            final key = row['filter_key'] as String;
            optionsByKey
                .putIfAbsent(key, () => [])
                .add(row as Map<String, dynamic>);
          }
        } catch (_) {
          // Table not created yet — the legacy array still works.
        }
      }

      if (mounted) {
        setState(() {
          _categoryFilterDefs = defs;
          _filterOptionRows = optionsByKey;
          _filtersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _filtersLoading = false);
    }
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
    _startingPriceController = TextEditingController(
        text: widget.vendorData['starting_price']?.toString() ?? '');
    _capacityMinController = TextEditingController(
        text: widget.vendorData['capacity_min']?.toString() ?? '');
    _capacityMaxController = TextEditingController(
        text: widget.vendorData['capacity_max']?.toString() ?? '');
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
    _startingPriceController.dispose();
    _capacityMinController.dispose();
    _capacityMaxController.dispose();
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
      final filePath = '${sanitizeStorageName(vendorName)}/$fileName';

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
        'guest_capacity': _guestCapacityController.text.trim(),
        // null (not 0) when blank, so an unset number means "no answer" and
        // the range filters skip this vendor rather than matching them at 0.
        'starting_price': int.tryParse(_startingPriceController.text.trim()),
        'capacity_min': int.tryParse(_capacityMinController.text.trim()),
        'capacity_max': int.tryParse(_capacityMaxController.text.trim()),
        'contact_email': _emailController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'website_url': _websiteController.text.trim(),
        'style_keywords': _styleKeywordsController.text.trim(),
        'social_media_links': _collectSocialMediaLinks(),
        'vendor_state': selectedStates,
        'vendor_county':
            servesUtah(selectedStates) ? selectedCounties : <String>[],
        'image_url': allImageUrls,
        'filter_values': _filterValues,
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
            _buildLocationPickerTile(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Full Address',
              hint: 'Filled in from the map. No storefront? Keep just your city.',
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

            if (servesUtah(selectedStates)) ...[
              _buildMultiSelectField(
                label: 'Utah Counties Served',
                // Keep any older free-typed value visible so it can be removed.
                items: [
                  ...kUtahCounties,
                  ...selectedCounties.where((c) => !kUtahCounties.contains(c)),
                ],
                selectedItems: selectedCounties,
                onChanged: (values) {
                  setState(() {
                    selectedCounties = values;
                  });
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Choose "Any" if you travel anywhere in Utah.',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Pricing Section
            _buildSectionHeader('Pricing'),
            const SizedBox(height: 16),
            // Two fields, one job each: a number the filters can match on,
            // and free text that couples actually read. They are deliberately
            // not merged — "$1,500–$3,800 depending on season" cannot be
            // compared numerically, and 2500 alone tells a couple nothing.
            _buildTextField(
              controller: _startingPriceController,
              label: 'Starting Price',
              hint: 'Lowest price a couple could pay, e.g. 2500',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 6),
            FieldHint(
              'Numbers only. This is what couples filter by — leave it blank '
              'and price filters will skip you entirely.',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Pricing Details',
              hint: 'e.g. \$1,500–\$3,800 depending on season',
            ),
            const SizedBox(height: 6),
            FieldHint(
              'Shown on your profile exactly as you write it.',
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Guest Capacity'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _capacityMinController,
                    label: 'Minimum Guests',
                    hint: 'e.g. 50',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _capacityMaxController,
                    label: 'Maximum Guests',
                    hint: 'e.g. 300',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FieldHint(
              'Couples filter by this range. Two numbers, not one: a venue '
              'that holds 50–300 should match a couple searching for 200.',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _guestCapacityController,
              label: 'Capacity Details',
              hint: 'e.g. 150 seated, 300 for a standing reception',
            ),
            const SizedBox(height: 6),
            FieldHint(
              'Optional. Shown on your profile exactly as you write it.',
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

            // Category Details Section
            if (_filtersLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_categoryFilterDefs.isNotEmpty) ...[
              _buildSectionHeader('Category Details'),
              const SizedBox(height: 8),
              Text(
                'These details help couples find you when filtering by category.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 16),
              // Shared with the create form so the two cannot drift: the
              // create page previously offered no filter questions at all.
              VendorFilterPicker(
                filterGroups: _categoryFilterDefs,
                optionsByKey: _filterOptionRows,
                selected: _filterValues,
                onChanged: (key, values) =>
                    setState(() => _filterValues[key] = values),
              ),
              const SizedBox(height: 8),
            ],

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
            // The pin is the source of truth: fill the address and the short
            // "City, ST" label, and pre-select the state/county it falls in.
            _addressController.text = result.address;
            if (result.cityLabel.isNotEmpty) {
              _locationController.text = result.cityLabel;
            }
            if (kUsStates.contains(result.state) &&
                !selectedStates.contains(result.state)) {
              selectedStates = [...selectedStates, result.state];
            }
            if (result.state == 'Utah' &&
                kUtahCounties.contains(result.county) &&
                selectedCounties.isEmpty) {
              selectedCounties = [result.county];
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
    /// Optional display text per item. Items are the values that get stored;
    /// labels are what the vendor reads. Falls back to the item itself.
    Map<String, String>? itemLabels,
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
                  itemLabels?[item] ?? item,
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