import 'package:flutter/material.dart';

class QuestionSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> questions;
  final Map<int, int> currentAnswers;
  final Function(int questionId, int value) onAnswerChanged;
  final bool isReadOnly;

  const QuestionSection({
    super.key,
    required this.title,
    required this.questions,
    required this.currentAnswers,
    required this.onAnswerChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CHANGEMENT : Le titre a maintenant un conteneur avec un fond gris
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 24.0, bottom: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title, 
            // La taille du titre est légèrement ajustée pour l'harmonie
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ),
        
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300)
          ),
          child: Column(
            children: questions.asMap().entries.map((entry) {
              final int index = entry.key;
              final Map<String, dynamic> q = entry.value;

              final questionId = q['id'] as int;
              final questionText = q['nom_question'] as String;

              return Container(
                decoration: BoxDecoration(
                  border: index != questions.length - 1
                      ? Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                        )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      // CHANGEMENT : Taille de la police réduite pour la compacité
                      child: Text(questionText, style: Theme.of(context).textTheme.bodyMedium)
                    ),
                    
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 0,
                          runSpacing: 0,
                          alignment: WrapAlignment.end,
                          children: List.generate(5, (i) {
                            final scoreValue = i + 1;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<int>(
                                  value: scoreValue,
                                  groupValue: currentAnswers[questionId],
                                  onChanged: isReadOnly
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            onAnswerChanged(questionId, value);
                                          }
                                        },
                                ),
                                Text('$scoreValue'),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}