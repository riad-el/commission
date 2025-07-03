import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Importation ajoutée pour debugPrint

class ApiService {
  static const String _baseUrl = 'http://www.cmc.pixwellagency.com/public/api/';

  static Future<Map<String, dynamic>?> login(String matricule, String password) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}wc-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'matricule': matricule,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != 0) { // Assuming '0' indicates an error from API
        return {
          'token': data['data']['token'],
          'membre': data['data']['membre'],
          'commission': data['data']['commission'],
          'membres_commission': data['data']['membres_commission'],
          'filiere_commission': data['data']['filiere_commission'],
          'questions_filiere': data['data']['questions_filiere'],
        };
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> dashboard(String token, String commissionId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}wc-dashboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'commission_id': commissionId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return {
          'candidats': data['data']['candidats'],
          'total_passe': data['data']['total_passe'],
          'total_non_passe': data['data']['total_non_passe'],
          'commission': data['data']['commission'],
          'membres_commission': data['data']['membres_commission'],
        };
      }
    }
    return null;
  }

  // Nouvelle méthode pour récupérer les données de la grille (candidat + notes existantes)
  static Future<Map<String, dynamic>?> getGrilleData(String token, String cin, String commissionId) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}wc-grille-data'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'cin': cin,
        'commission_id': commissionId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      } else {
        // Gérer les erreurs spécifiques de l'API ici si nécessaire
        debugPrint('Erreur API getGrilleData: ${data['message']}');
      }
    } else {
      debugPrint('Erreur HTTP getGrilleData: ${response.statusCode} - ${response.body}');
    }
    return null;
  }

  // Nouvelle méthode pour soumettre l'évaluation de la grille
  static Future<Map<String, dynamic>?> submitGrilleEvaluation(
      String token, String cin, String commissionId, double noteGenerale, Map<int, int> notesParQuestion) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}wc-submit-grille'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'cin': cin,
        'commission_id': commissionId,
        'note_generale': noteGenerale,
        // Convertir la Map<int, int> en Map<String, int> pour JSON
        'notes_par_question': notesParQuestion.map((k, v) => MapEntry(k.toString(), v)),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data; // Retourne l'objet succès/message
      } else {
        debugPrint('Erreur API submitGrilleEvaluation: ${data['message']}');
      }
    } else {
      debugPrint('Erreur HTTP submitGrilleEvaluation: ${response.statusCode} - ${response.body}');
    }
    return null;
  }


// ==========================================================
  // NOUVELLE FONCTION POUR LE DASHBOARD ADMIN
  // ==========================================================
  static Future<Map<String, dynamic>?> getFiliereStats(String token) async {
    // Votre route est un POST, donc nous utilisons http.post
    // Le token est envoyé dans le corps de la requête pour authentification
    final response = await http.post(
      Uri.parse('${_baseUrl}wc-admin-dashboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // On suppose que la réponse succès contient une clé 'status' égale à 'success'
      if (data['status'] == 'success') {
        return data; // Retourne l'objet entier qui contient la clé 'data'
      }
    } else {
      debugPrint('Erreur HTTP getFiliereStats: ${response.statusCode} - ${response.body}');
    }
    return null;
  }
   // ==========================================================
  // NOUVELLE FONCTION POUR LE LOGIN ADMIN
  // ==========================================================

  static Future<Map<String, dynamic>?> adminLogin(String username, String password) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}wc-admin-login'), // Appelle la nouvelle route
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data']; // Retourne seulement les données utiles
      }
    }
    return null; // Retourne null en cas d'échec
  }
}
