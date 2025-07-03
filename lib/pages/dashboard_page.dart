import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'dart:math' as math;

// Le widget pour le graphique en anneau (inchangé)
class _EvaluationDoughnutChart extends StatelessWidget {
  final int evaluatedCount;
  final int pendingCount;

  const _EvaluationDoughnutChart({
    required this.evaluatedCount,
    required this.pendingCount,
  });

  Widget _buildLegendItem(BuildContext context, Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = evaluatedCount + pendingCount;
    final evaluatedPercentage = total > 0 ? (evaluatedCount / total) : 0.0;
    final pendingPercentage = total > 0 ? (pendingCount / total) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Progression de l\'Évaluation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _DoughnutChartPainter(
                  evaluatedPercentage: evaluatedPercentage,
                  pendingPercentage: pendingPercentage,
                  evaluatedColor: Colors.teal.shade400,
                  pendingColor: Colors.amber.shade300,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total Candidats',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, Colors.teal.shade400, 'Évalués', evaluatedCount),
                const SizedBox(width: 10),
                _buildLegendItem(context, Colors.amber.shade300, 'En attente', pendingCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Le CustomPainter pour le graphique (inchangé)
class _DoughnutChartPainter extends CustomPainter {
  final double evaluatedPercentage;
  final double pendingPercentage;
  final Color evaluatedColor;
  final Color pendingColor;

  _DoughnutChartPainter({
    required this.evaluatedPercentage,
    required this.pendingPercentage,
    required this.evaluatedColor,
    required this.pendingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final strokeWidth = 20.0;
    paint.strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    double startAngle = -math.pi / 2;

    if (evaluatedPercentage > 0) {
      final sweepAngle = 2 * math.pi * evaluatedPercentage;
      paint.color = evaluatedColor;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    if (pendingPercentage > 0) {
      final sweepAngle = 2 * math.pi * pendingPercentage;
      paint.color = pendingColor;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _DoughnutChartPainter ||
           oldDelegate.evaluatedPercentage != evaluatedPercentage ||
           oldDelegate.pendingPercentage != pendingPercentage ||
           oldDelegate.evaluatedColor != evaluatedColor ||
           oldDelegate.pendingColor != pendingColor;
  }
}

// Widget principal de la page
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- Variables d'état ---
  List<Map<String, dynamic>> candidats = [];
  int totalPasse = 0;
  int totalNonPasse = 0;
  Map<String, dynamic>? commissionDetails;
  
  bool _isLoading = true;
  String _searchQuery = '';
  int? selectedRowIndex;
  
  // Clé pour gérer l'ouverture du Drawer sur petits écrans
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAndFetchData();
  }

  Future<void> _loadAndFetchData({int? reselectId}) async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final token = html.window.localStorage['token'];
    final commissionId = html.window.localStorage['commission_id'];

    if (token == null || commissionId == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    
    final storedCommissionDetailsJson = html.window.localStorage['commission_details'];
    if (storedCommissionDetailsJson != null && mounted) {
      setState(() {
        commissionDetails = jsonDecode(storedCommissionDetailsJson);
      });
    }

    final response = await ApiService.dashboard(token, commissionId);

    if (response != null && mounted) {
      setState(() {
        candidats = List<Map<String, dynamic>>.from(response['candidats'] as List? ?? []);
        totalPasse = response['total_passe'] as int? ?? 0;
        totalNonPasse = response['total_non_passe'] as int? ?? 0;
        commissionDetails = response['commission'] as Map<String, dynamic>?;
        _isLoading = false;
        
        if (reselectId != null) {
          final newIndex = _getFilteredCandidats().indexWhere((c) => c['id'] == reselectId);
          if (newIndex != -1) {
            selectedRowIndex = newIndex;
          } else {
            selectedRowIndex = null;
          }
        } else {
          selectedRowIndex = null;
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement du tableau de bord. Veuillez vous reconnecter.')),
      );
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _navigateToGrille() async {
    if (selectedRowIndex == null) return;
    final filteredCandidats = _getFilteredCandidats();
    if (selectedRowIndex! >= filteredCandidats.length) return;

    final selectedCandidat = filteredCandidats[selectedRowIndex!];
    final cin = selectedCandidat['CIN'];
    final candidatId = selectedCandidat['id'];

    final result = await Navigator.pushNamed(
      context, 
      '/grille', 
      arguments: {'cin': cin},
    );

    if (result == true) {
      _loadAndFetchData(reselectId: candidatId);
    }
  }

  void onEvaluer() => _navigateToGrille();
  void onImprimer() => _navigateToGrille();

  List<Map<String, dynamic>> _getFilteredCandidats() {
    if (_searchQuery.isEmpty) return candidats;
    
    final queryLower = _searchQuery.toLowerCase();
    return candidats.where((candidat) {
      return (candidat['CIN']?.toLowerCase().contains(queryLower) ?? false) ||
             (candidat['cef']?.toLowerCase().contains(queryLower) ?? false) ||
             (candidat['Nom']?.toLowerCase().contains(queryLower) ?? false) ||
             (candidat['Prenom']?.toLowerCase().contains(queryLower) ?? false) ||
             (candidat['filiere_concernee']?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  // ==========================================================
  // NOUVEAUX WIDGETS DE MISE EN PAGE RESPONSIVE
  // ==========================================================

  /// Construit la barre latérale, utilisée soit de manière fixe, soit dans un Drawer.
  Widget buildSidebar(BuildContext context) {
    final List<dynamic> filieres = commissionDetails?['filieres'] ?? [];
    final List<dynamic> membres = commissionDetails?['membres'] ?? [];

    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              commissionDetails?['nom'] ?? 'Commission',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 30, thickness: 1.5, color: Colors.grey),
            
            Text(
              'Filière(s) Gérée(s):',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (filieres.isEmpty)
              const Text('Aucune filière assignée.', style: TextStyle(fontStyle: FontStyle.italic))
            else
              for (final filiere in filieres)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text("- ${filiere['nom_filiere']}", style: Theme.of(context).textTheme.bodyLarge),
                ),

            const SizedBox(height: 20),
            Text(
              'Membres:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (membres.isEmpty)
              const Text('Aucun membre assigné.', style: TextStyle(fontStyle: FontStyle.italic))
            else
              for (final membre in membres)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(membre['nom'] as String, style: Theme.of(context).textTheme.bodyLarge),
                ),
            
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                html.window.localStorage.clear();
                Navigator.pushReplacementNamed(context, '/');
              },
              icon: Icon(Icons.logout, color: Theme.of(context).primaryColor),
              label: Text('Déconnexion', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      )
    );
  }

  /// Construit le panneau principal avec le graphique et la table
  Widget buildMainContent(List<Map<String, dynamic>> filteredCandidats, bool isSmallScreen) {
    
    // Logique pour déterminer l'état des boutons
    Map<String, dynamic>? selectedCandidat;
    if (selectedRowIndex != null && selectedRowIndex! < filteredCandidats.length) {
      selectedCandidat = filteredCandidats[selectedRowIndex!];
    }
    final bool isCandidatSelected = selectedCandidat != null;
    final bool selectedHasPassed = isCandidatSelected && (selectedCandidat['a_passe'] ?? false);

    // Widget pour le panneau des candidats (recherche, boutons, tableau)
    final candidatePanel = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() {
                  _searchQuery = value;
                  selectedRowIndex = null;
                }),
                decoration: InputDecoration(
                  labelText: 'Rechercher un candidat...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(onPressed: isCandidatSelected && selectedHasPassed ? onImprimer : null, icon: const Icon(Icons.print), label: const Text('Imprimer')),
            const SizedBox(width: 16),
            ElevatedButton.icon(onPressed: isCandidatSelected && !selectedHasPassed ? onEvaluer : null, icon: const Icon(Icons.edit), label: const Text('Évaluer')),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: buildCustomDataTable(filteredCandidats),
        ),
      ],
    );

    // Retourne la disposition appropriée en fonction de la taille de l'écran
    if (isSmallScreen) {
      // Sur petit écran, on empile tout verticalement dans une ListView pour le défilement
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _EvaluationDoughnutChart(evaluatedCount: totalPasse, pendingCount: totalNonPasse),
          const SizedBox(height: 24),
          // Le Container avec une hauteur fixe est nécessaire pour que la Column dans ListView fonctionne
          SizedBox(height: 600, child: candidatePanel), 
        ],
      );
    } else {
      // Sur grand écran, on utilise la disposition en Row
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.topCenter,
                child: _EvaluationDoughnutChart(
                  evaluatedCount: totalPasse,
                  pendingCount: totalNonPasse,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: candidatePanel,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCandidateRow(Map<String, dynamic> candidat, int index) {
    final bool isSelected = selectedRowIndex == index;
    final bool aPasse = candidat['a_passe'] ?? false;

    Color getRowColor() {
      if (aPasse) return Colors.green.withOpacity(0.15);
      if (isSelected) return Theme.of(context).primaryColor.withOpacity(0.1);
      return Colors.transparent;
    }

    return InkWell(
      onTap: () => setState(() => selectedRowIndex = isSelected ? null : index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: getRowColor(),
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            SizedBox(width: 30, child: Checkbox(value: isSelected, onChanged: (val) => setState(() => selectedRowIndex = val! ? index : null))),
            Expanded(flex: 2, child: Text(candidat['CIN'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
            Expanded(flex: 2, child: Text(candidat['cef'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
            Expanded(flex: 2, child: Text(candidat['Nom'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
            Expanded(flex: 2, child: Text(candidat['Prenom'] ?? '', style: Theme.of(context).textTheme.bodyMedium)),
            Expanded(flex: 3, child: Text(candidat['filiere_concernee'] ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }

  Widget buildCustomDataTable(List<Map<String, dynamic>> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 30),
                Expanded(flex: 2, child: Text('CIN', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
                Expanded(flex: 2, child: Text('Cef', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
                Expanded(flex: 2, child: Text('Nom', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
                Expanded(flex: 2, child: Text('Prénom', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
                Expanded(flex: 3, child: Text('Filière', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) => _buildCandidateRow(data[index], index),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Point de rupture pour la mise en page responsive
    const double breakpoint = 900.0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            const SizedBox(width: 12),
            Text('Tableau de Bord CMC', style: Theme.of(context).appBarTheme.titleTextStyle),
          ],
        ),
      ),
      // Le Drawer ne s'affiche que sur les petits écrans
      drawer: MediaQuery.of(context).size.width < breakpoint 
        ? Drawer(child: buildSidebar(context)) 
        : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < breakpoint;
                if (isSmallScreen) {
                  // Mise en page pour petits écrans (verticale)
                  return buildMainContent(_getFilteredCandidats(), true);
                } else {
                  // Mise en page pour grands écrans (horizontale)
                  return Row(
                    children: [
                      buildSidebar(context),
                      Expanded(
                        child: buildMainContent(_getFilteredCandidats(), false),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }
}