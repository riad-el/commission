import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'package:web/web.dart' as web;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

// Importations des widgets séparés
import 'grille_widgets/question_section.dart';
import 'grille_widgets/total_score_display.dart';
import 'grille_widgets/action_buttons.dart';


class GrillePage extends StatefulWidget {
  const GrillePage({super.key});

  @override
  State<GrillePage> createState() => _GrillePageState();
}

class _GrillePageState extends State<GrillePage> {
  String? candidatCin;
  Map<String, dynamic>? candidatDetails;
  Map<String, dynamic>? commissionDetails;

  List<Map<String, dynamic>> softSkillsQuestions = [];
  List<Map<String, dynamic>> specifiqueQuestions = [];
  final Map<int, int> _currentAnswers = {};

  bool _isLoading = true;
  String _errorMessage = '';
  bool _dataLoadedOnce = false;
  
  bool _aPasseEvaluation = false;

  pw.MemoryImage? _logoHeader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoadedOnce) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      candidatCin = args?['cin'];
      
      if (candidatCin == null) {
        setState(() {
          _errorMessage = 'CIN du candidat non fourni.';
          _isLoading = false;
        });
        return;
      }
      _dataLoadedOnce = true;
      _loadGrilleData();
    }
  }

  Future<void> _loadGrilleData() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    final token = web.window.localStorage['token'];
    final commissionId = web.window.localStorage['commission_id'];
    if (token == null || commissionId == null) {
      setState(() { _errorMessage = 'Token ou Commission ID manquant.'; _isLoading = false; });
      return;
    }
    try {
      final softskillJson = web.window.localStorage['questions_softskill'];
      final specifiqueJson = web.window.localStorage['questions_specifique'];
      softSkillsQuestions = softskillJson != null ? List<Map<String, dynamic>>.from(jsonDecode(softskillJson)) : [];
      specifiqueQuestions = specifiqueJson != null ? List<Map<String, dynamic>>.from(jsonDecode(specifiqueJson)) : [];
      
      final apiResponse = await ApiService.getGrilleData(token, candidatCin!, commissionId);
      
      if (apiResponse != null) {
        candidatDetails = apiResponse['candidat'];
        commissionDetails = apiResponse['commission'];
        _aPasseEvaluation = apiResponse['a_passe_evaluation'] ?? false;
        
        final notesData = apiResponse['notes_existantes_par_question'];
        _currentAnswers.clear();

        if (notesData is Map) {
          notesData.forEach((key, value) {
            _currentAnswers[int.parse(key)] = value as int;
          });
        }
        await _loadHeaderImage();
        
      } else {
        _errorMessage = 'Impossible de charger les données.';
      }

    } catch (e) {
      _errorMessage = 'Erreur : $e';
    } finally {
      if(mounted){ setState(() { _isLoading = false; }); }
    }
  }

  Future<void> _loadHeaderImage() async {
    final bytes = await rootBundle.load('assets/images/ENTETE.png');
    _logoHeader = pw.MemoryImage(bytes.buffer.asUint8List());
  }

  int get _calculatedTotalScore => [ ...softSkillsQuestions.map((q) => q['id'] as int), ...specifiqueQuestions.map((q) => q['id'] as int) ].fold(0, (sum, id) => sum + (_currentAnswers[id] ?? 0));
  int get _maxPossibleScore => (softSkillsQuestions.length + specifiqueQuestions.length) * 5;

  Future<void> _submitEvaluation() async {
    if (candidatCin == null || commissionDetails == null) return;
    final allIds = [ ...softSkillsQuestions.map((q) => q['id'] as int), ...specifiqueQuestions.map((q) => q['id'] as int) ];
    for (var id in allIds) {
      if (!_currentAnswers.containsKey(id)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir toutes les notes.')));
        return;
      }
    }
    setState(() => _isLoading = true);
    final token = web.window.localStorage['token'];
    final commissionId = commissionDetails!['id'].toString();
    final response = await ApiService.submitGrilleEvaluation(token!, candidatCin!, commissionId, _calculatedTotalScore.toDouble(), _currentAnswers);
    if (mounted) {
      if (response?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Évaluation enregistrée ✅')));
        Navigator.of(context).pop(true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur d\'enregistrement')));
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _printEvaluationGrid() async {
    if (_logoHeader == null || candidatDetails == null || commissionDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les données ne sont pas prêtes pour l'impression."))
      );
      return;
    }
    
    final poleNom = commissionDetails?['filieres']?.first?['pole']?['nom_pole'] ?? 'N/A';
    final commissionNom = commissionDetails?['nom'] ?? 'N/A'; // Récupérer le nom de la commission

    pw.TableRow _buildPdfBlocRow({
      required String title,
      required List<Map<String, dynamic>> questions,
    }) {
      if (questions.isEmpty) return pw.TableRow(children: List.generate(8, (_) => pw.Container()));

      const borderDeco = pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 0.5)));
      
      return pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.full, 
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Transform.rotate(
                angle: -3.14 / 2,
                child: pw.Text(title, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: questions.map((q) {
                return pw.Container(
                  height: 22,
                  alignment: pw.Alignment.centerLeft,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  decoration: borderDeco,
                  child: pw.Text(q['nom_question'] ?? '', style: pw.TextStyle(fontSize: 8)),
                );
              }).toList(),
            ),
            for (int score = 1; score <= 5; score++)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: questions.map((q) {
                  final answer = _currentAnswers[q['id']] ?? 0;
                  return pw.Container(
                    height: 22,
                    alignment: pw.Alignment.center,
                    decoration: borderDeco,
                    child: pw.Text((answer == score) ? 'X' : '', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  );
                }).toList(),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: questions.map((q) => pw.Container(height: 22, decoration: borderDeco)).toList(),
            ),
          ],
        );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(
          children: [
            if (_logoHeader != null) pw.Image(_logoHeader!, width: 500),
            pw.SizedBox(height: 20),
            pw.Center( child: pw.Text('Entretien des candidats CMC : Grille d\'évaluation', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)) ),
            pw.SizedBox(height: 15),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Table(
                  columnWidths: { 0: const pw.IntrinsicColumnWidth(), 1: const pw.FlexColumnWidth(2) },
                  children: [
                    pw.TableRow(children: [ pw.Text('Secteur Groupe: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(poleNom) ]),
                    pw.TableRow(children: [ pw.Text('Secteur : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(poleNom) ]),
                    pw.TableRow(children: [ pw.Text('Filière: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(commissionDetails?['filieres']?.first['nom_filiere'] ?? '') ]),
                    // ==========================================================
                    // AJOUT DU NOM DE LA COMMISSION
                    // ==========================================================
                    pw.TableRow(children: [ pw.Text('Commission: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(commissionNom) ]),
                  ],
                )),
                pw.SizedBox(width: 20),
                pw.Expanded(child: pw.Table(
                  columnWidths: { 0: const pw.IntrinsicColumnWidth(), 1: const pw.FlexColumnWidth(2) },
                  children: [
                    pw.TableRow(children: [ pw.Text('Date d\'entretien : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())) ]),
                    pw.TableRow(children: [ pw.Text('Session: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Juillet 2025') ]),
                    pw.TableRow(children: [ pw.Text('Nom & Prénom: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('${candidatDetails?['Prenom'] ?? ''} ${candidatDetails?['Nom'] ?? ''}') ]),
                    pw.TableRow(children: [ pw.Text('CIN Candidat: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(candidatDetails?['CIN'] ?? '') ]),
                  ],
                )),
              ]
            ),
            pw.SizedBox(height: 10),
          ]
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
            columnWidths: { 0: const pw.FixedColumnWidth(25), 1: const pw.FlexColumnWidth(4), 2: const pw.FixedColumnWidth(15), 3: const pw.FixedColumnWidth(15), 4: const pw.FixedColumnWidth(15), 5: const pw.FixedColumnWidth(15), 6: const pw.FixedColumnWidth(15), 7: const pw.FlexColumnWidth(2), },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.Container(height: 25, alignment: pw.Alignment.center, child: pw.Text('Bloc', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(alignment: pw.Alignment.centerLeft, padding: const pw.EdgeInsets.all(6), child: pw.Text('CRITÈRE D\'APPRÉCIATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  for (int i = 1; i <= 5; i++) pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(6), child: pw.Text('$i', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(6), child: pw.Text('OBS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              _buildPdfBlocRow(title: 'Soft Skills', questions: softSkillsQuestions),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Container(), pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.centerLeft, child: pw.Text('TPSS / Total Soft Skills', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(), pw.Container(), pw.Container(), pw.Container(), pw.Container(),
                  pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.center, child: pw.Text('${softSkillsQuestions.fold(0, (sum, q) => sum + (_currentAnswers[q['id']] ?? 0))}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              _buildPdfBlocRow(title: 'Spécifique', questions: specifiqueQuestions),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Container(),
                  pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.centerLeft, child: pw.Text('TPM / Total Métier', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(), pw.Container(), pw.Container(), pw.Container(), pw.Container(),
                  pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.center, child: pw.Text('${specifiqueQuestions.fold(0, (sum, q) => sum + (_currentAnswers[q['id']] ?? 0))}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
            ]
          ),
          pw.SizedBox(height: 10),
          pw.Text('Note entretien : $_calculatedTotalScore / $_maxPossibleScore', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: { 0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(3), 2: const pw.FlexColumnWidth(2) },
            children: [
              pw.TableRow(children: [
                pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.center, child: pw.Text('APPRECIATION DES MEMBRES DE LA COMMISSION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.center, child: pw.Text('NOMS DES EVALUATEURS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                pw.Container(padding: const pw.EdgeInsets.all(4), alignment: pw.Alignment.center, child: pw.Text('EMARGEMENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
              ]),
              pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.full,
                children: [
                  pw.Container(decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1)))),
                  pw.Column(children: List.generate(3, (index) => pw.Container(
                    height: 25,
                    decoration: pw.BoxDecoration( border: pw.Border( right: const pw.BorderSide(color: PdfColors.black, width: 1), bottom: index < 2 ? const pw.BorderSide(color: PdfColors.black, width: 1) : pw.BorderSide.none, ))
                  ))),
                   pw.Column(children: List.generate(3, (index) => pw.Container(
                    height: 25,
                    decoration: pw.BoxDecoration( border: pw.Border( bottom: index < 2 ? const pw.BorderSide(color: PdfColors.black, width: 1) : pw.BorderSide.none, ))
                  ))),
                ]
              )
            ]
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_errorMessage.isNotEmpty) {
        return Scaffold(body: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))));
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Grille : ${candidatDetails?['Prenom'] ?? ''} ${candidatDetails?['Nom'] ?? ''}')
        ),
        bottomNavigationBar: BottomAppBar(
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                TotalScoreDisplay(
                  calculatedScore: _calculatedTotalScore,
                  maxScore: _maxPossibleScore,
                ),
                const Spacer(), 
                ActionButtons(
                  isLoading: _isLoading,
                  aPasseEvaluation: _aPasseEvaluation,
                  onSubmit: _submitEvaluation,
                  onPrint: _printEvaluationGrid,
                ),
              ],
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 80),
                      child: QuestionSection(
                        title: 'Soft Skills',
                        questions: softSkillsQuestions,
                        currentAnswers: _currentAnswers,
                        isReadOnly: _aPasseEvaluation,
                        onAnswerChanged: (questionId, value) {
                          setState(() {
                            _currentAnswers[questionId] = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 80),
                      child: QuestionSection(
                        title: 'Spécifique',
                        questions: specifiqueQuestions,
                        currentAnswers: _currentAnswers,
                        isReadOnly: _aPasseEvaluation,
                        onAnswerChanged: (questionId, value) {
                          setState(() {
                            _currentAnswers[questionId] = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestionSection(
                      title: 'Soft Skills',
                      questions: softSkillsQuestions,
                      currentAnswers: _currentAnswers,
                      isReadOnly: _aPasseEvaluation,
                      onAnswerChanged: (questionId, value) {
                        setState(() {
                          _currentAnswers[questionId] = value;
                        });
                      },
                    ),
                    QuestionSection(
                      title: 'Spécifique',
                      questions: specifiqueQuestions,
                      currentAnswers: _currentAnswers,
                      isReadOnly: _aPasseEvaluation,
                      onAnswerChanged: (questionId, value) {
                        setState(() {
                          _currentAnswers[questionId] = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            }
          }
        )
      ),
    );
  }
}