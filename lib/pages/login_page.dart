import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  Future<void> _login() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() => _erro = 'Email ou senha incorretos');
    } catch (e) {
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.directions_bus_rounded, size: 72, color: cor.primary),
              const SizedBox(height: 16),
              Text(
                'Maruim Acadêmico',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: cor.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transporte Universitário',
                textAlign: TextAlign.center,
                style: TextStyle(color: cor.outline),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _erro!,
                    style: TextStyle(color: cor.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregando ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: cor.primary,
                  foregroundColor: cor.onPrimary,
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
