import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<List<String>?> showCategorySelectionSheet(
  BuildContext context, {
  required List<String> categories,
  bool isRegenerate = false,
}) async {
  final Set<String> selectedCategories = Set.from(categories);

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (_, setSheetState) {
        final allSelected = selectedCategories.length == categories.length;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isRegenerate ? 'Regenerate Checklist' : 'Build Your Checklist',
                style: GoogleFonts.bodoniModa(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the categories to include',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              if (isRegenerate) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCC7AA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF7B3F61)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will replace your existing checklist',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF7B3F61),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select All',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E3E3E),
                    ),
                  ),
                  Switch(
                    value: allSelected,
                    activeColor: const Color(0xFF7B3F61),
                    onChanged: (v) {
                      setSheetState(() {
                        if (v) {
                          selectedCategories.addAll(categories);
                        } else {
                          selectedCategories.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: categories
                      .map((cat) => CheckboxListTile(
                            title: Text(
                              cat,
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                            value: selectedCategories.contains(cat),
                            activeColor: const Color(0xFF7B3F61),
                            dense: true,
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == true) {
                                  selectedCategories.add(cat);
                                } else {
                                  selectedCategories.remove(cat);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCategories.isEmpty
                      ? null
                      : () {
                          Navigator.pop(sheetCtx, selectedCategories.toList());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    disabledBackgroundColor: const Color(0xFFDCC7AA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Generate',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ),
  );
}
