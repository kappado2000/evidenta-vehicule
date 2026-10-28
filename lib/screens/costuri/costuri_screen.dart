import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/date_provider.dart';

class CosturiScreen extends StatelessWidget {
  const CosturiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final date = context.watch<DateProvider>();
    final costuri = date.costuriPeCategorieAnCurent;
    final total = costuri.values.fold<num>(0, (a, b) => a + b);
    final anCurent = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(title: Text('Costuri $anCurent')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Total cheltuit anul curent'),
                  const SizedBox(height: 4),
                  Text('${total.toStringAsFixed(0)} lei',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...costuri.entries.map((e) => Card(
                child: ListTile(
                  title: Text(e.key),
                  trailing: Text('${e.value.toStringAsFixed(0)} lei',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }
}
