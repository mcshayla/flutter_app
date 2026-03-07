import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import 'guest_form.dart';

class GuestListPage extends StatefulWidget {
  const GuestListPage({super.key});

  @override
  State<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<GuestListPage> {
  String _searchQuery = '';
  String? _filterGroup;
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final allGuests = appState.guests;
        final statusCounts = appState.guestStatusCounts;

        // Get unique groups
        final groups = allGuests
            .map((g) => g['group_name'] as String? ?? '')
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        // Filter
        var filteredGuests = allGuests.where((g) {
          if (_searchQuery.isNotEmpty) {
            final name = '${g['first_name'] ?? ''} ${g['last_name'] ?? ''}'.toLowerCase();
            if (!name.contains(_searchQuery.toLowerCase())) return false;
          }
          if (_filterGroup != null && g['group_name'] != _filterGroup) return false;
          if (_filterStatus != null && g['rsvp_status'] != _filterStatus) return false;
          return true;
        }).toList();

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
              'Guest List',
              style: GoogleFonts.bodoniModa(
                color: const Color(0xFF7B3F61),
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restaurant_menu, color: Color(0xFF7B3F61)),
                tooltip: 'Dietary Summary',
                onPressed: () => _showDietarySheet(context, allGuests),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Color(0xFF7B3F61)),
                tooltip: 'Copy as CSV',
                onPressed: () => _exportToClipboard(context, allGuests),
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary counts
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3F61),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountStat('Total', '${allGuests.length}', Colors.white),
                    _buildCountStat('Accepted', '${statusCounts['accepted'] ?? 0}',
                        const Color(0xFFDCC7AA)),
                    _buildCountStat('Declined', '${statusCounts['declined'] ?? 0}',
                        Colors.white70),
                    _buildCountStat('Pending', '${statusCounts['invited'] ?? 0}',
                        Colors.white70),
                  ],
                ),
              ),

              // Search and filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search guests...',
                          hintStyle: GoogleFonts.montserrat(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String?>(
                      icon: const Icon(Icons.filter_list, color: Color(0xFF7B3F61)),
                      onSelected: (v) => setState(() => _filterStatus = v),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: null, child: Text('All Statuses')),
                        const PopupMenuItem(value: 'not_sent', child: Text('Not Sent')),
                        const PopupMenuItem(value: 'invited', child: Text('Invited')),
                        const PopupMenuItem(value: 'accepted', child: Text('Accepted')),
                        const PopupMenuItem(value: 'declined', child: Text('Declined')),
                        const PopupMenuItem(value: 'maybe', child: Text('Maybe')),
                      ],
                    ),
                    if (groups.isNotEmpty)
                      PopupMenuButton<String?>(
                        icon: const Icon(Icons.group, color: Color(0xFF7B3F61)),
                        onSelected: (v) => setState(() => _filterGroup = v),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: null, child: Text('All Groups')),
                          ...groups.map((g) => PopupMenuItem(value: g, child: Text(g))),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Guest list
              Expanded(
                child: filteredGuests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: const Color(0xFFDCC7AA)),
                            const SizedBox(height: 16),
                            Text(
                              'Add guests to your list',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF6E6E6E),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredGuests.length,
                        itemBuilder: (context, index) {
                          final guest = filteredGuests[index];
                          return _GuestTile(
                            guest: guest,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GuestForm(existingGuest: guest),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF7B3F61),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuestForm()),
              );
            },
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showDietarySheet(BuildContext context, List<Map<String, dynamic>> guests) {
    // Guests with any dietary or meal info
    final withInfo = guests.where((g) {
      final diet = (g['dietary_restrictions'] ?? '').toString().trim();
      final meal = (g['meal_preference'] ?? '').toString().trim();
      return diet.isNotEmpty || meal.isNotEmpty;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Dietary & Meal Info',
              style: GoogleFonts.bodoniModa(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${withInfo.length} of ${guests.length} guests have dietary or meal info',
              style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF6E6E6E)),
            ),
            const SizedBox(height: 12),
            withInfo.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No dietary or meal info added yet',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF6E6E6E),
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.separated(
                      itemCount: withInfo.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final g = withInfo[i];
                        final name =
                            '${g['first_name'] ?? ''} ${g['last_name'] ?? ''}'.trim();
                        final diet = (g['dietary_restrictions'] ?? '').toString().trim();
                        final meal = (g['meal_preference'] ?? '').toString().trim();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    const Color(0xFF7B3F61).withOpacity(0.1),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.bodoniModa(
                                    fontSize: 13,
                                    color: const Color(0xFF7B3F61),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        )),
                                    if (meal.isNotEmpty)
                                      Text('Meal: $meal',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: const Color(0xFF6E6E6E),
                                          )),
                                    if (diet.isNotEmpty)
                                      Text('Dietary: $diet',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                          )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _exportToClipboard(BuildContext context, List<Map<String, dynamic>> guests) {
    // Tab-separated so pasting into Excel/Sheets splits into columns automatically
    String clean(dynamic v) =>
        (v ?? '').toString().replaceAll('\t', ' ').replaceAll('\r', ' ');

    final buffer = StringBuffer();
    buffer.writeln(
      'First Name\tLast Name\tEmail\tPhone\tGroup\tRSVP\tMeal Preference\tDietary Restrictions\tPlus One\tPlus One Name\tNotes',
    );
    for (final g in guests) {
      buffer.writeln([
        clean(g['first_name']),
        clean(g['last_name']),
        clean(g['email']),
        clean(g['phone']),
        clean(g['group_name']),
        clean(g['rsvp_status']),
        clean(g['meal_preference']),
        clean(g['dietary_restrictions']),
        clean(g['plus_one_allowed'] == true ? 'Yes' : 'No'),
        clean(g['plus_one_name']),
        clean(g['notes']),
      ].join('\t'));
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Guest list copied! Paste into Excel or Google Sheets.',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF7B3F61),
      ),
    );
  }

  Widget _buildCountStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.bodoniModa(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }
}

class _GuestTile extends StatelessWidget {
  final Map<String, dynamic> guest;
  final VoidCallback onTap;

  const _GuestTile({required this.guest, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'invited':
        return Colors.orange;
      case 'maybe':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'not_sent':
        return 'Not Sent';
      case 'invited':
        return 'Invited';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'maybe':
        return 'Maybe';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${guest['first_name'] ?? ''} ${guest['last_name'] ?? ''}'.trim();
    final group = guest['group_name'] as String? ?? '';
    final status = guest['rsvp_status'] as String? ?? 'not_sent';
    final plusOne = guest['plus_one_allowed'] == true;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF7B3F61).withOpacity(0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (plusOne) ...[
            const SizedBox(width: 4),
            Text('+1', style: GoogleFonts.montserrat(fontSize: 11, color: const Color(0xFF6E6E6E))),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.isNotEmpty)
            Text(group,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: const Color(0xFF6E6E6E))),
          if ((guest['dietary_restrictions'] ?? '').toString().trim().isNotEmpty)
            Text(
              'Dietary: ${guest['dietary_restrictions']}',
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: Colors.red.shade700),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _statusLabel(status),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _statusColor(status),
          ),
        ),
      ),
    );
  }
}
