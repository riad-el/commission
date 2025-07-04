import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_widgets/filiere_status_card.dart';
import 'dart:html' as html;
import 'dart:convert';
// CORRECTION : Importation du package avec un préfixe pour éviter les conflits de noms
import 'package:excel/excel.dart' as excel_lib;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> _filieresData = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final token = html.window.localStorage['token'];
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session invalide. Veuillez vous reconnecter."))
        );
        setState(() { _isLoading = false; });
      }
      return;
    }

    try {
      final response = await ApiService.getFiliereStats(token);
      if (mounted && response != null && response['status'] == 'success') {
        setState(() {
          _filieresData = List<Map<String, dynamic>>.from(response['data'] as List);
          _isLoading = false;
        });
      } else if (mounted) {
         throw Exception("Erreur lors de la récupération des statistiques.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()))
        );
        setState(() { _isLoading = false; });
      }
    }
  }

  void _logout() {
    html.window.localStorage.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _showExportDialog() async {
    List<int> selectedFiliereIds = [];
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Exporter les notes'),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filieresData.length,
                  itemBuilder: (context, index) {
                    final filiere = _filieresData[index];
                    final filiereId = filiere['id_filiere'];
                    final isSelected = selectedFiliereIds.contains(filiereId);
                    return CheckboxListTile(
                      title: Text(filiere['nom_filiere']),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedFiliereIds.add(filiereId);
                          } else {
                            selectedFiliereIds.remove(filiereId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FilledButton(
                  child: const Text('Exporter'),
                  onPressed: selectedFiliereIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _handleExport(selectedFiliereIds);
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleExport(List<int> filiereIds) async {
    setState(() => _isExporting = true);
    
    try {
      final token = html.window.localStorage['token'];
      if (token == null) throw Exception("Session invalide.");

      final response = await ApiService.exportNotes(token, filiereIds);

      if (mounted && response != null && response['status'] == 'success') {
        _generateAndDownloadXlsx(response['data'] as List<dynamic>);
      } else {
        throw Exception("Erreur lors de la récupération des données pour l'export.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _generateAndDownloadXlsx(List<dynamic> data) {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune donnée à exporter.")));
      return;
    }

    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheetObject = excel['Feuil1'];

    // CORRECTION : Utilisation du préfixe 'excel_lib' et des bonnes valeurs
    excel_lib.CellStyle headerStyle = excel_lib.CellStyle(
         // Gris clair
        fontFamily: excel_lib.getFontFamily(excel_lib.FontFamily.Calibri),
        bold: true,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        verticalAlign: excel_lib.VerticalAlign.Center,
        leftBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        rightBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        topBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        bottomBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin)
    );

    excel_lib.CellStyle cellStyle = excel_lib.CellStyle(
        fontFamily: excel_lib.getFontFamily(excel_lib.FontFamily.Calibri),
        leftBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        rightBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        topBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
        bottomBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin)
    );

    final List<String> headers = (data.first as Map<String, dynamic>).keys.toList();
    final List<excel_lib.CellValue> headerCells = headers.map((header) => excel_lib.TextCellValue(header)).toList();
    sheetObject.appendRow(headerCells);
    
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }
    
    for (var i = 0; i < data.length; i++) {
      final rowData = data[i] as Map<String, dynamic>;
      final List<excel_lib.CellValue> rowCells = rowData.values.map((cellValue) {
        return excel_lib.TextCellValue(cellValue?.toString() ?? '');
      }).toList();
      sheetObject.appendRow(rowCells);
      
      for (var j = 0; j < rowCells.length; j++) {
        var cell = sheetObject.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
        cell.cellStyle = cellStyle;
      }
    }

    for (var i = 0; i < headers.length; i++) {
      sheetObject.setColumnAutoFit(i);
    }

    excel.save(fileName: "export_notes_entretien.xlsx");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervision des Évaluations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser les données',
            onPressed: _isLoading ? null : _fetchData,
          ),
          IconButton(
            icon: _isExporting 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : const Icon(Icons.download),
            tooltip: 'Exporter les notes',
            onPressed: _isLoading || _isExporting ? null : _showExportDialog,
          ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary, 
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 700) {
                    crossAxisCount = 2;
                  }
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _filieresData.length,
                    itemBuilder: (context, index) {
                      final filiere = _filieresData[index];
                      return FiliereStatusCard(
                        nomFiliere: filiere['nom_filiere'] ?? 'N/A',
                        totalCandidats: filiere['total_candidats'] ?? 0,
                        candidatsEvalues: filiere['candidats_evalues'] ?? 0,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
