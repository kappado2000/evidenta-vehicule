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
        return Icons.toll_outlined;
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
                    ? Colors.red.shade700
                    : a.zileRamase <= 7
                    ? Colors.orange.shade800
                    : Colors.amber.shade800;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: culoare.withValues(alpha: 0.4)),
                  ),
                  color: culoare.withValues(alpha: 0.08),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 5, color: culoare),
                        Expanded(
                          child: ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: culoare.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    _iconaPentru(a.tip),
                                    color: culoare,
                                  ),
                                ),
                                if (a.expirat || a.zileRamase <= 7)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: culoare,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.priority_high,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              a.titlu,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(a.mesaj),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: culoare,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                a.expirat ? 'EXPIRAT' : '${a.zileRamase}z',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
