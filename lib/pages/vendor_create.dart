// vendor_create.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:provider/provider.dart';
import '../utils/image_compress.dart';
import '../utils/image_utils.dart';
import '../appstate.dart';
import '../widgets/field_hint.dart';
import '../widgets/vendor_filter_picker.dart';
import 'vendor_dashboard.dart';
import 'location_picker_page.dart';
import '../utils/regions.dart';

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
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _capacityMinController = TextEditingController();
  final _capacityMaxController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _styleKeywordsController = TextEditingController();
  final _guestCapacityController = TextEditingController();

  // Social media controllers
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _pinterestController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();

  // Category dropdown
  String? _selectedCategory;
  List<String> _categoryOptions = [];

  // Category-specific filter answers. Loaded once a category is chosen, since
  // the questions depend on it. Without these a brand-new vendor is invisible
  // to every chip filter until they go back and edit their profile.
  List<Map<String, dynamic>> _categoryFilterDefs = [];
  Map<String, List<Map<String, dynamic>>> _filterOptionRows = {};
  Map<String, List<String>> _filterValues = {};

  // State and County
  List<String> selectedStates = [];
  List<String> selectedCounties = [];
  final List<String> availableStates = kUsStates;

  // Location picker
  double? _pickedLat;
  double? _pickedLng;
  String _pickedAddress = '';

  // Photo management
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await supabase
          .from('categories')
          .select('name')
          .order('display_order', ascending: true);
setState(() {
        _categoryOptions = (rows as List).map((r) => r['name'] as String).toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  /// Loads the filter questions for [category] and clears any answers given
  /// for the previous one — a Venue's amenities are meaningless on a Florist.
  Future<void> _loadCategoryFilters(String? category) async {
    setState(() {
      _categoryFilterDefs = [];
      _filterOptionRows = {};
      _filterValues = {};
    });
    if (category == null || category.isEmpty) return;

    try {
      final defs = await supabase
          .from('category_filters')
          .select()
          .eq('category_name', category)
          .order('display_order', ascending: true);

      final keys = [
        for (final d in defs as List)
          if (d['filter_key'] != null) d['filter_key'] as String
      ];

      // Options now live in filter_options; the legacy category_filters.options
      // array stays as a fallback for categories not yet migrated.
      final Map<String, List<Map<String, dynamic>>> optionRows = {};
      if (keys.isNotEmpty) {
        final rows = await supabase
            .from('filter_options')
            .select()
            .inFilter('filter_key', keys)
            .order('display_order', ascending: true);
        for (final row in rows as List) {
          optionRows
              .putIfAbsent(row['filter_key'] as String, () => [])
              .add(row as Map<String, dynamic>);
        }
      }

      if (!mounted) return;
      setState(() {
        _categoryFilterDefs = List<Map<String, dynamic>>.from(defs);
        _filterOptionRows = optionRows;
      });
    } catch (e) {
      // Filters simply won't appear; the rest of the form still works.
      print('Error loading category filters: $e');
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
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
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final remaining = limit - _selectedImages.length;
        if (remaining <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maximum of $limit photos allowed')),
          );
          return;
        }
        setState(() {
          _selectedImages.addAll(images.take(remaining));
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

    void addLinks(String text) {
      links.addAll(
        text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
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

  Future<List<String>> _uploadImages(String vendorName) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
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

  Future<void> _createVendor() async {
    if (!_formKey.currentState!.validate()) return;
    // The map pin replaces the old free-text "Location" field, so it's
    // what fills the city shown on vendor cards.
    if (_pickedLat == null || _pickedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please set your location on the map.',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: const Color(0xFF7B3F61),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final businessName = _businessNameController.text.trim();
      
      // Create vendor record FIRST (without images)
      final payload = <String, dynamic>{
        'vendor_name': businessName,
        'vendor_description': _descriptionController.text.trim(),
        'vendor_category': _selectedCategory ?? '',
        'vendor_location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'vendor_price': _priceController.text.trim(),
        'guest_capacity': _guestCapacityController.text.trim(),
        // null (not 0) when blank, so an unset number means "no answer" and
        // the range filters skip this vendor rather than matching them at 0.
        'starting_price': int.tryParse(_startingPriceController.text.trim()),
        'capacity_min': int.tryParse(_capacityMinController.text.trim()),
        'capacity_max': int.tryParse(_capacityMaxController.text.trim()),
        // Drop groups the vendor skipped: an empty list would read as "answered
        // with nothing", and the detail page treats absence as "not filled in".
        'filter_values': <String, List<String>>{
          for (final entry in _filterValues.entries)
            if (entry.value.isNotEmpty) entry.key: entry.value,
        },
        'contact_email': _emailController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'website_url': _websiteController.text.trim(),
        'style_keywords': _styleKeywordsController.text.trim(),
        'social_media_links': _collectSocialMediaLinks(),
        'vendor_state': selectedStates,
        'vendor_county':
            servesUtah(selectedStates) ? selectedCounties : <String>[],
        'vendor_user_id': widget.userId,
        'is_claimed': true,
        'claimed_at': DateTime.now().toIso8601String(),
      };
      if (_pickedLat != null) payload['latitude'] = _pickedLat;
      if (_pickedLng != null) payload['longitude'] = _pickedLng;

      final vendorResponse = await supabase
          .from('vendors')
          .insert(payload)
          .select()
          .single();

      // Now upload images (vendor record exists, so policy will pass)
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorDashboard()),
        );
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
        backgroundColor: Colors.transparent,
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
DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                labelStyle: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF7B3F61)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                ),
              ),
              items: _categoryOptions.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: GoogleFonts.montserrat(fontSize: 12)),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedCategory = val);
                _loadCategoryFilters(val);
              },
              validator: (val) => val == null ? 'Please select a category' : null,
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
            // Kept identical to vendor_edit_profile.dart.
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

            // Category-specific questions (Venue Type, Amenities, …). Appears
            // once a category is picked; categories with no filters defined
            // render nothing at all.
            if (_categoryFilterDefs.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Category Details',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'These details help couples find you when filtering.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 16),
              VendorFilterPicker(
                filterGroups: _categoryFilterDefs,
                optionsByKey: _filterOptionRows,
                selected: _filterValues,
                onChanged: (key, values) =>
                    setState(() => _filterValues[key] = values),
              ),
            ],
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