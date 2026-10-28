import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _parolaCtrl = TextEditingController();
  bool _modInregistrare = false;
  bool _seIncarca = false;
  String? _eroare;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _parolaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _seIncarca = true;
      _eroare = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      if (_modInregistrare) {
        await auth.inregistreaza(_emailCtrl.text.trim(), _parolaCtrl.text);
      } else {
        await auth.login(_emailCtrl.text.trim(), _parolaCtrl.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _eroare = _mesajEroare(e.code));
    } catch (e) {
      setState(() => _eroare = 'Eroare neașteptată: $e');
    } finally {
      if (mounted) setState(() => _seIncarca = false);
    }
  }

  String _mesajEroare(String cod) {
    switch (cod) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email sau parolă greșită.';
      case 'email-already-in-use':
        return 'Există deja un cont cu acest email.';
      case 'weak-password':
        return 'Parola trebuie să aibă cel puțin 6 caractere.';
      case 'invalid-email':
        return 'Adresă de email invalidă.';
      default:
        return 'Eroare autentificare ($cod).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 64,
                      color: Color(0xFF0891B2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Evidența Auto',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Email invalid'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _parolaCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Parolă',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimum 6 caractere'
                          : null,
                    ),
                    if (_eroare != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _eroare!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _seIncarca ? null : _submit,
                      child: _seIncarca
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _modInregistrare
                                  ? 'Creează cont'
                                  : 'Autentificare',
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() => _modInregistrare = !_modInregistrare),
                      child: Text(
                        _modInregistrare
                            ? 'Ai deja cont? Autentifică-te'
                            : 'Nu ai cont? Creează unul',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
