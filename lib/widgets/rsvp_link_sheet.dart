import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';

// TODO: Set this to your Amplify site URL (no trailing slash)
const String _rsvpBaseUrl = 'https://YOUR_AMPLIFY_SITE/rsvp.html';

void showRsvpLinkSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RsvpLinkSheet(),
  );
}

class _RsvpLinkSheet extends StatefulWidget {
  const _RsvpLinkSheet();

  @override
  State<_RsvpLinkSheet> createState() => _RsvpLinkSheetState();
}

class _RsvpLinkSheetState extends State<_RsvpLinkSheet> {
  bool _showCreate = false;
  bool _saving = false;

  final _labelController = TextEditingController();
  final _groupController = TextEditingController();

  final Map<String, bool> _fields = {
    'email': false,
    'phone': false,
    'address': true,
    'dietary': false,
    'meal': false,
    'notes': false,
    'plus_one': false,
  };

  final Map<String, String> _fieldLabels = {
    'email': 'Email address',
    'phone': 'Phone number',
    'address': 'Mailing address',
    'dietary': 'Dietary restrictions',
    'meal': 'Meal preference',
    'notes': 'Notes / message',
    'plus_one': 'Additional guest count',
  };

  @override
  void dispose() {
    _labelController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  String _buildLink(String token) => '$_rsvpBaseUrl?token=$token';

  void _copyLink(BuildContext ctx, String token) {
    Clipboard.setData(ClipboardData(text: _buildLink(token)));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Link copied!', style: GoogleFonts.montserrat(fontSize: 13)),
        backgroundColor: const Color(0xFF7B3F61),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createLink() async {
    setState(() => _saving = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final result = await appState.createGuestLinkConfig(
      label: _labelController.text.trim(),
      groupName: _groupController.text.trim(),
      fieldsEnabled: Map<String, bool>.from(_fields),
    );
    setState(() {
      _saving = false;
      if (result != null) {
        _showCreate = false;
        _labelController.clear();
        _groupController.clear();
        _fields.updateAll((k, _) => false);
        _fields['address'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final configs = appState.guestLinkConfigs;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F5F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'RSVP Links',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                      const Spacer(),
                      if (!_showCreate)
                        TextButton.icon(
                          onPressed: () => setState(() => _showCreate = true),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('New Link', style: GoogleFonts.montserrat(fontSize: 13)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7B3F61)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_showCreate) _buildCreateForm(context),
                      if (!_showCreate && configs.isEmpty)
                        _buildEmpty(),
                      if (!_showCreate)
                        ...configs.map((c) => _buildLinkCard(context, c, appState)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.link, size: 56, color: const Color(0xFFDCC7AA)),
          const SizedBox(height: 12),
          Text(
            'No RSVP links yet',
            style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF6E6E6E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a link to share with guests so they\ncan add themselves to your list.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6E6E6E)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showCreate = true),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Create First Link', style: GoogleFonts.montserrat(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B3F61),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCC7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New RSVP Link',
            style: GoogleFonts.bodoniModa(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7B3F61),
            ),
          ),
          const SizedBox(height: 14),

          _field(_labelController, 'Link label (e.g. "Bride\'s Side")'),
          const SizedBox(height: 12),
          _field(_groupController, 'Assign guests to group (optional)'),
          const SizedBox(height: 16),

          Text(
            'Fields to include on the form:',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E3E3E),
            ),
          ),
          const SizedBox(height: 4),
          ..._fieldLabels.entries.map((e) => CheckboxListTile(
                title: Text(e.value, style: GoogleFonts.montserrat(fontSize: 13)),
                value: _fields[e.key],
                onChanged: (v) => setState(() => _fields[e.key] = v ?? false),
                activeColor: const Color(0xFF7B3F61),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showCreate = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B3F61),
                    side: const BorderSide(color: Color(0xFF7B3F61)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.montserrat(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _createLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Create', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, Map<String, dynamic> config, AppState appState) {
    final label = (config['label'] as String? ?? '').isNotEmpty
        ? config['label'] as String
        : 'Untitled Link';
    final group = config['group_name'] as String? ?? '';
    final token = config['token'] as String;
    final link = _buildLink(token);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCC7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3E3E3E),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _confirmDelete(context, config['id'] as String, label, appState),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (group.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Group: $group',
              style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6E6E6E)),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              link,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF6E6E6E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyLink(context, token),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text('Copy Link', style: GoogleFonts.montserrat(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B3F61),
                    side: const BorderSide(color: Color(0xFF7B3F61)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildFieldChips(config['fields_enabled']),
        ],
      ),
    );
  }

  Widget _buildFieldChips(dynamic fieldsEnabled) {
    if (fieldsEnabled == null) return const SizedBox.shrink();
    final Map<String, dynamic> fields = Map<String, dynamic>.from(fieldsEnabled as Map);
    final active = fields.entries.where((e) => e.value == true).map((e) => _fieldLabels[e.key] ?? e.key).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: active
          .map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3F61).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.montserrat(fontSize: 10, color: const Color(0xFF7B3F61)),
                ),
              ))
          .toList(),
    );
  }

  void _confirmDelete(BuildContext context, String id, String label, AppState appState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Link?', style: GoogleFonts.bodoniModa()),
        content: Text(
          'The link "$label" will stop working. Guests who already submitted will remain in your list.',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.montserrat()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              appState.deleteGuestLinkConfig(id);
            },
            child: Text('Delete', style: GoogleFonts.montserrat(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: GoogleFonts.montserrat(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF7B3F61)),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDCC7AA))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDCC7AA))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7B3F61), width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
