import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shop_list/data/categories.dart';
import 'package:shop_list/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shop_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();

  var enteredName = '';
  var enteredQuantity = 1;
  var selectedCategory = categories[Categories.vegetables]!;
  var _isSaving = false;

  void saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving= true;
      });
      _formKey.currentState!.save();

      final response = await http.post(
        Uri.https("flutter-prep-dd172-default-rtdb.firebaseio.com",
            "shopping-list.json"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'name': enteredName,
            'quantity': enteredQuantity,
            'category': selectedCategory.title,
          },
        ),
      );

      setState(() {
        _isSaving =false;
      });

      Map<String, dynamic> resData = json.decode(response.body);

      if (!context.mounted) return;
      Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'],
          name: enteredName,
          quantity: enteredQuantity,
          category: selectedCategory,
        ),
      );

      // Navigator.of(context).pop(GroceryItem(
      //   id: DateTime.now().toString(),
      //   name: enteredName,
      //   quantity: enteredQuantity,
      //   category: selectedCategory,
      // ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.length > 50) {
                    return 'Please enter a valid name';
                  }
                  return null;
                },
                onSaved: (value) {
                  enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) < 1) {
                          return 'Please enter a valid positive valid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        selectedCategory = value!;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving? null: _formKey.currentState?.reset,
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving?null: saveItem,
                    child:_isSaving? const SizedBox(width: 16,height: 16,child: CircularProgressIndicator()): const Text('Save item'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
