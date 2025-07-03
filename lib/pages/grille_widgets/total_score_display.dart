import 'package:flutter/material.dart';

class TotalScoreDisplay extends StatelessWidget {
  final int calculatedScore;
  final int maxScore;

  const TotalScoreDisplay({
    super.key,
    required this.calculatedScore,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    // Le padding excessif a été retiré.
    // Le widget parent (BottomAppBar) s'occupe de l'espacement.
    return Text(
      'Note Totale : $calculatedScore / $maxScore',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}