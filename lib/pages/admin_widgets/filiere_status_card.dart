import 'package:flutter/material.dart';

class FiliereStatusCard extends StatelessWidget {
  final String nomFiliere;
  final int totalCandidats;
  final int candidatsEvalues;

  const FiliereStatusCard({
    super.key,
    required this.nomFiliere,
    required this.totalCandidats,
    required this.candidatsEvalues,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = totalCandidats > 0 ? (candidatsEvalues / totalCandidats) : 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Pour que les couleurs de fond ne dépassent pas les coins arrondis
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomFiliere,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(), // Pousse le contenu suivant vers le bas
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percentage,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
                      ),
                      Center(
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Candidats Évalués',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '$candidatsEvalues / $totalCandidats',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progression',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Spacer(), // Pousse le contenu vers le haut et le bas
          ],
        ),
      ),
    );
  }
}