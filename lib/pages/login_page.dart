import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAdminLogin = false; // Variable d'état pour la case à cocher

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Logique de connexion conditionnelle
    if (_isAdminLogin) {
      // Connexion en tant qu'administrateur
      final result = await ApiService.adminLogin(username, password);
      if (result != null && mounted) {
        html.window.localStorage['token'] = result['token'] as String;
        html.window.localStorage['admin_name'] = result['admin']['nom'] ?? '';
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiants admin incorrects ou problème de connexion')),
        );
      }
    } else {
      // Connexion en tant que membre (logique existante)
      final result = await ApiService.login(username, password);
      if (result != null && mounted) {
        html.window.localStorage['token'] = result['token'] as String;
        html.window.localStorage['membre_nom'] = result['membre']['nom'] ?? '';
        final commission = result['commission'];
        if (commission != null) {
          html.window.localStorage['commission_id'] = commission['id'].toString();
          html.window.localStorage['commission_details'] = jsonEncode(commission);
        }
        if (result['questions_filiere'] != null) {
          if (result['questions_filiere']['softskill'] != null) {
            html.window.localStorage['questions_softskill'] = jsonEncode(result['questions_filiere']['softskill']);
          }
          if (result['questions_filiere']['specifique'] != null) {
            html.window.localStorage['questions_specifique'] = jsonEncode(result['questions_filiere']['specifique']);
          }
        }
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiants membre incorrects ou problème de connexion')),
        );
      }
    }

    if(mounted){
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', height: 120),
                  const SizedBox(height: 30),
                  Text(
                    'Bienvenue à CMC',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: _isAdminLogin ? 'Nom d\'utilisateur Admin' : 'Matricule Membre',
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("Se connecter en tant qu'administrateur"),
                    value: _isAdminLogin,
                    onChanged: (newValue) {
                      setState(() {
                        _isAdminLogin = newValue ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}