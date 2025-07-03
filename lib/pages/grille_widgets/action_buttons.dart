import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool aPasseEvaluation; // Nouvelle variable
  final VoidCallback onSubmit;
  final VoidCallback onPrint;

  const ActionButtons({
    super.key,
    required this.isLoading,
    required this.aPasseEvaluation, // Requis dans le constructeur
    required this.onSubmit,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    // Affiche le bouton Imprimer si l'évaluation est déjà passée
    if (aPasseEvaluation) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.print_outlined),
        onPressed: isLoading ? null : onPrint,
        label: const Text('Imprimer PDF'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
        ),
      );
    }

    // Sinon, affiche le bouton Enregistrer
    return ElevatedButton.icon(
      icon: const Icon(Icons.save),
      onPressed: isLoading ? null : onSubmit,
      label: const Text('Enregistrer l\'Évaluation'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
      ),
    );
  }
}