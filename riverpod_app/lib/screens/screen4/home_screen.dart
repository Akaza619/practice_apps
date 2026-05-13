import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_app/screens/screen4/item_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Counter App")),
      body: item.isEmpty
          ? Center(child: Text("No data found"))
          : ListView.builder(
              itemCount: item.length,
              itemBuilder: (context, index) {
                final itemDetail = item[index];
                return ListTile(
                  title: Text(itemDetail.name),
                  trailing: Row(
                    mainAxisSize: .min,
                    children: [
                      IconButton(
                        onPressed: () {
                          ref
                              .read(itemProvider.notifier)
                              .updateItem(itemDetail.id, 'Update Item');
                        },
                        icon: Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(itemProvider.notifier)
                              .deleteItem(itemDetail.id);
                        },
                        icon: Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(itemProvider.notifier).addItem('NewItem');
        },
      ),
    );
  }
}
