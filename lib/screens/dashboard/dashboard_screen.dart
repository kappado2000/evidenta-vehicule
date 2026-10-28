import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alerta.dart';
import '../../providers/date_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  IconData _iconaPentru(TipAlerta tip) {
    switch (tip) {
      case TipAlerta.itp:
        return Icons.fact_check_outlined;
      case TipAlerta.rovinieta:
        return Icons.route_outlined;
      case TipAlerta.asigurare:
        return Icons.shield_outlined;
      case TipAlerta.revizie:
        return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = context.watch<DateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Alerte')),
      body: date.seIncarca
          ? const Center(child: CircularProgressIndicator())
          : date.alerte.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nicio alertă activă. Toate documentele sunt în termen.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: date.alerte.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = date.alerte[i];
                    final culoare = a.expirat
                        ? Colors.red
                        : a.zileRamase <= 7
                            ? Colors.orange
                            : Colors.amber.shade700;
                    return Card(
                      child: ListTile(
                        leading: Icon(_iconaPentru(a.tip), color: culoare),
                        title: Text(a.titlu),
                        subtitle: Text(a.mesaj),
                        trailing: Text(
                          a.expirat ? '${-a.zileRamase}z' : '${a.zileRamase}z',
                          style: TextStyle(
                              color: culoare, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
