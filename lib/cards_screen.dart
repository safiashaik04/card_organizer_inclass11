import 'package:flutter/material.dart';
import 'database_helper.dart';

final dbHelper = DatabaseHelper();

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


class CardsScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final data = await dbHelper.getCardsByFolder(widget.folder['id']);
    setState(() => cards = data);
  }

  Future<void> _addCard() async {
  int maxNumber = await dbHelper.getMaxCardNumberInFolder(widget.folder['id']);

  // Check the folder limit
  if (maxNumber >= 6) {
    _showDialog('This folder can only hold 6 cards.');
    return;
  }

  // Insert a new card with proper numbering
  await dbHelper.insertCard({
    'name': 'Card ${maxNumber + 1}',
    'suit': widget.folder['name'],
    'imageUrl': imageForSuit(widget.folder['name']),
    'folderId': widget.folder['id'],
  });

  _loadCards();
}




  Future<void> _deleteCard(int id) async {
    await dbHelper.deleteCard(id);
    _loadCards();
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder['name']} Cards'),
        backgroundColor: Colors.teal.shade600,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            child: Stack(
              children: [
                Center(
                  child: Image.network(
                    card['imageUrl'] ?? imageForSuit(card['suit']),
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCard(card['id']),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
