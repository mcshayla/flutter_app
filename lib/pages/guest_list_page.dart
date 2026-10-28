import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../appstate.dart';
import '../utils/app_styles.dart';
import '../widgets/plan_panels.dart';
import '../widgets/rsvp_link_sheet.dart';
import 'guest_form.dart';

class GuestListPage extends StatefulWidget {
  final bool embedded;

  const GuestListPage({super.key, this.embedded = false});

  @override
  State<GuestListPage> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<GuestListPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final allGuests = appState.guests;
        final panel = RefreshIndicator(
          color: AppStyles.plum,
          onRefresh: () => appState.loadGuests(),
          child: GuestPanel(
            guests: allGuests,
            headcount: appState.totalGuestHeadcount,
            statusCounts: appState.guestStatusCounts,
            onAddGuest: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuestForm()),
            ),
            onOpenGuest: (guest) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GuestForm(existingGuest: guest)),
            ),
            onRsvpLinks: () => showRsvpLinkSheet(context),
            onMeals: () => _showDietarySheet(context, allGuests),
            onExport: () => _exportToClipboard(context, allGuests),
          ),
        );

        if (widget.embedded) {
          return ColoredBox(color: AppStyles.cream, child: panel);
        }
        return Scaffold(
          backgroundColor: AppStyles.cream,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppStyles.plum),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Guest List', style: AppStyles.display(22)),
          ),
          body: panel,
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
              style: GoogleFonts.playfairDisplay(
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
                                  style: GoogleFonts.playfairDisplay(
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
}
