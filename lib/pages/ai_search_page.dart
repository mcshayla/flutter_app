import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../widgets/card.dart';
import 'dart:convert';
import '../appstate.dart';


class SearchBatch {
    final String query;
    final List<dynamic> results;

    SearchBatch({required this.query, required this.results});
  }

class AISearchPage extends StatefulWidget {
  const AISearchPage({super.key});
  @override
  State<AISearchPage> createState() => _AISearchPageState();

}

class _AISearchPageState extends State<AISearchPage> {
  final TextEditingController _controller = TextEditingController();
   final ScrollController _scrollController = ScrollController(); // ← here
  List<SearchBatch> _searchBatches = [];
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadAppState();
  }

  Future<void> _loadAppState() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isLoaded) {
      await appState.loadInitialData();
    }
    setState(() {
      _loadingData = false;
    });
  }

  void _performSearch() async {

    final query = _controller.text;
    _controller.clear();
    setState(() {});
    print(query);
    // final url = Uri.parse("http://127.0.0.1:8000/search");
    final url = Uri.parse("http://10.0.2.2:8000/search");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": query}),
      );

      if (response.statusCode == 200){
        final result = jsonDecode(response.body);
        print("Top results: $result");

        setState(() {

        _searchBatches.add(SearchBatch(query: query, results: result));
        });
      }

    } catch (e) {
      print("error $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (_loadingData) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
  child: _searchBatches.isEmpty
      ? Center(child: Text("Describe the type of wedding you want!"))
      : ListView.builder(
          controller: _scrollController,
          itemCount: _searchBatches.length,
          itemBuilder: (context, batchIndex) {
            final batch = _searchBatches[batchIndex];
            final query = batch.query;
            final results = batch.results;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Results for: "$query"',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Grid of vendors
                  GridView.builder(
                    shrinkWrap: true, // Important to let it fit inside Column
                    physics: NeverScrollableScrollPhysics(), // Disable inner scroll
                    itemCount: results.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // two columns
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final vendor_id = results[index];
                      final category = appState.vendorIdToCategory[vendor_id];
                      final vendorList = appState.allCategorizedMap[category] ?? [];
                      final vendor = vendorList.firstWhere(
                        (v) => v['vendor_id'] == vendor_id,
                        orElse: () => {},
                      );

                      return CustomCard(
                        title: vendor['vendor_name'] ?? "",
                        description: vendor['vendor_description'] ?? "",
                        imageUrl: vendor['image_url'] ?? "",
                        isHearted: appState
                                .lovedVendorUUIDsCategorizedMap[vendor_id]
                                ?.contains(vendor['vendor_id']) ??
                            false,
                        onHeartToggled: (hearted) {
                          appState.toggleHeart(vendor['vendor_id'], hearted);
                        },
                        isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[vendor['vendor_id']]?.toLowerCase()] == vendor['vendor_id'],
                        onDiamondToggled: (diamonded) {
                          appState.toggleDiamond(vendor['vendor_id'], diamonded);
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
),
        Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search, // Enter key shows search
          onSubmitted: (value) => _performSearch(),
          decoration: InputDecoration(
            hintText: 'Type your search...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: _performSearch, // Trigger search on click
            ),
          ),
        ),
      ), 
      ],
    );
  }
}
