import 'package:flutter/material.dart';

/// T30: search bar, trending chips, Nxtspot rail, recent notifications.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SearchBar(hintText: 'Search cricket news', leading: Icon(Icons.search)),
            const SizedBox(height: 24),
            Text('Nxtspot', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Grassroots stories land here in T30.'),
          ],
        ),
      ),
    );
  }
}
