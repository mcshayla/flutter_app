import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorComparePage extends StatelessWidget {
  final List<Map<String, dynamic>> vendors;

  const VendorComparePage({required this.vendors, super.key});

  @override
  Widget build(BuildContext context) {
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
          'Compare Vendors',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: vendors.length < 2
          ? Center(
              child: Text(
                'Select at least 2 vendors to compare',
                style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF6E6E6E)),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const labelColWidth = 90.0;
                final vendorColWidth = ((constraints.maxWidth - labelColWidth - 32) / vendors.length)
                    .clamp(120.0, 220.0);

                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF7B3F61).withOpacity(0.1),
                          ),
                          columnSpacing: 8,
                          columns: [
                            DataColumn(
                              label: SizedBox(
                                width: labelColWidth,
                                child: Text('',
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            ...vendors.map((v) => DataColumn(
                                  label: SizedBox(
                                    width: vendorColWidth,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            ((v['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                                                ? (v['image_url'] as List<dynamic>)[0].toString()
                                                : 'https://picsum.photos/100/100',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 60,
                                              height: 60,
                                              color: const Color(0xFFDCC7AA),
                                              child: const Icon(Icons.business),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v['vendor_name'] ?? '',
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF7B3F61),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                          rows: [
                            _buildRow('Location',
                                vendors.map((v) => (v['vendor_location'] ?? '-').toString()).toList(),
                                labelColWidth, vendorColWidth),
                            _buildRow('Price',
                                vendors.map((v) {
                                  final price = v['vendor_price'] ?? v['vendor_estimated_price'] ?? '-';
                                  return price.toString().isEmpty ? '-' : price.toString();
                                }).toList(),
                                labelColWidth, vendorColWidth),
                            _buildRow('Style',
                                vendors.map((v) => (v['style_keywords'] ?? '-').toString()).toList(),
                                labelColWidth, vendorColWidth),
                            _buildRow('Email',
                                vendors.map((v) => (v['contact_email'] ?? '-').toString()).toList(),
                                labelColWidth, vendorColWidth),
                            _buildRow('Phone',
                                vendors.map((v) => (v['contact_phone'] ?? '-').toString()).toList(),
                                labelColWidth, vendorColWidth),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  DataRow _buildRow(String label, List<String> values, double labelWidth, double colWidth) {
    return DataRow(cells: [
      DataCell(SizedBox(
        width: labelWidth,
        child: Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61))),
      )),
      ...values.map((v) => DataCell(
            SizedBox(
              width: colWidth,
              child: Text(v,
                  style: GoogleFonts.montserrat(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          )),
    ]);
  }
}
