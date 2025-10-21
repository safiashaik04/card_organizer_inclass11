import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'cards_screen.dart';

final dbHelper = DatabaseHelper();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
  final data = await dbHelper.getAllFolders();
  List<Map<String, dynamic>> foldersWithExtras = [];

  for (var folder in data) {
    final count = await dbHelper.getCardCountInFolder(folder['id']);
    final cards = await dbHelper.getCardsByFolder(folder['id']);

    String previewImage;
    if (cards.isNotEmpty && cards.first['imageUrl'] != null) {
      previewImage = cards.first['imageUrl'];  // first card image
    } else {
      previewImage = imageForSuit(folder['name']); // fallback
    }

    foldersWithExtras.add({
      ...folder,
      'cardCount': count,
      'previewImage': previewImage,
    });
  }

  setState(() => folders = foldersWithExtras);
}



String imageForSuit(String suit) {
  switch (suit) {
    case 'Hearts':
      return 'https://deckofcardsapi.com/static/img/AH.png';
    case 'Spades':
      return 'https://deckofcardsapi.com/static/img/AS.png';
    case 'Diamonds':
      return 'https://deckofcardsapi.com/static/img/AD.png';
    case 'Clubs':
      return 'https://deckofcardsapi.com/static/img/AC.png';
    default:
      return 'https://deckofcardsapi.com/static/img/back.png';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade600,
      ),
      body: GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  itemCount: folders.length,
  itemBuilder: (context, index) {
    final folder = folders[index];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CardsScreen(folder: folder)),
      ).then((_) => _loadFolders()), // refresh after returning
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview image of first card
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                folder['previewImage'],
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              folder['name'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${folder['cardCount']} cards inside',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  },
)


    );
  }
}
