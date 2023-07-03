import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop_list/data/categories.dart';
import 'package:shop_list/models/category.dart';
import 'package:shop_list/models/grocery_item.dart';
import 'package:shop_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final _groceryItems = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final response = await http.get(
      Uri.https(
        "flutter-prep-dd172-default-rtdb.firebaseio.com",
        "shopping-list.json",
      ),
    );

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final loadedItems = [];
    final Map<String, dynamic> listData = json.decode(response.body);
    for (final item in listData.entries) {
      Category category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    setState(() {
      _groceryItems.addAll(loadedItems);
      _isLoading = false;
    });
  }

  void newItem(BuildContext context) async {
    final grocery = await Navigator.of(context).push<GroceryItem?>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (grocery == null) return;
    setState(() {
      _groceryItems.add(grocery);
    });
  }

  void _removeItem(GroceryItem groceryItem) async {
    final index = _groceryItems.indexOf(groceryItem);
    setState(() {
      _groceryItems.remove(groceryItem);
    });

    final response = await http.delete(
      Uri.https(
        "flutter-prep-dd172-default-rtdb.firebaseio.com",
        "shopping-list/${groceryItem.id}.json",
      ),
    );

    if (response.statusCode >= 400) {
      _groceryItems.insert(index, groceryItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: CircularProgressIndicator());

    if (!_isLoading) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index]),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions:
            // _isLoading?[]:
            [
          IconButton(
            onPressed: () {
              newItem(context);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
