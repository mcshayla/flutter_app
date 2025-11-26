import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../widgets/card.dart';
import 'dart:convert';

class AISearchPage extends StatefulWidget {
  const AISearchPage({super.key});
  @override
  State<AISearchPage> createState() => _AISearchPageState();

}

class _AISearchPageState extends State<AISearchPage> {
  final TextEditingController _controller = TextEditingController();

  List<dynamic> _searchResults = [];

  void _performSearch() async {

    final query = _controller.text;
    _controller.clear();
    setState(() {});
    print(query);
    final url = Uri.parse("http://127.0.0.1:8000/search");
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
        _searchResults = result; // you'll need to declare _searchResults in your state
        });
      }

    } catch (e) {
      print("error ${e}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column( 
      children: [
        // Expanded(child: Center(child: Text("Main - cards go here"),),),
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

      Expanded( 
        child: _searchResults.isEmpty ?
        Text("Describe the type of wedding you want!")
        : ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
              final vendor_id_index = _searchResults[index];
              final row = 
              return CustomCard(
                title: item['vendor_name'] ?? "",
                description: item['vendor_description'] ?? "",
                imageUrl: item['image_url'] ?? "",
                isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                isDiamonded: false,
                onHeartToggled: (hearted) {
                  appState.toggleHeart(item['vendor_id'], hearted);
                },
          }
          )
         ),
      ]
    );
  }
}
