import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_widgets/filiere_status_card.dart';
import 'dart:html' as html;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> _filieresData = [];
  bool _isLoading = true;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _connectToWebSocket() {
    try {
      // NOTE: L'URL doit correspondre à votre configuration serveur.
      // Le format est 'ws://VOTRE_IP_OU_DOMAINE:PORT/app/VOTRE_CLE'
      final uri = Uri.parse('ws://www.cmc.pixwellagency.com:6001/app/base64:your-app-key');
      
      _channel = WebSocketChannel.connect(uri);

      _channel!.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': 'dashboard-admin'}
      }));

      _channel!.stream.listen((message) {
        final decodedMessage = jsonDecode(message);
        if (decodedMessage['event'] == 'evaluation.updated') {
          print('Mise à jour en temps réel reçue ! Rafraîchissement des données...');
          _fetchData();
        }
      }, onError: (error) {
        print('Erreur WebSocket: $error');
      });

    } catch (e) {
      print("Impossible de se connecter au WebSocket: $e");
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    if (_filieresData.isEmpty) {
      setState(() { _isLoading = true; });
    }

    final token = html.window.localStorage['token'];
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session invalide. Veuillez vous reconnecter."))
      );
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    final response = await ApiService.getFiliereStats(token);

    if (mounted && response != null && response['status'] == 'success') {
      setState(() {
        _filieresData = List<Map<String, dynamic>>.from(response['data'] as List);
        _isLoading = false;
      });
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la récupération des statistiques."))
      );
       setState(() { _isLoading = false; });
    }
  }

  void _logout() {
    // Vider le stockage local pour effacer le token
    html.window.localStorage.clear();
    // Rediriger vers la page de connexion
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervision des Évaluations'),
        actions: [
          // Bouton pour actualiser manuellement les données
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser les données',
            onPressed: _isLoading ? null : _fetchData,
          ),

          // ==========================================================
          // AJOUT DU BOUTON DE DÉCONNEXION
          // ==========================================================
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
            style: TextButton.styleFrom(
              // S'assure que la couleur du texte est correcte sur l'AppBar
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