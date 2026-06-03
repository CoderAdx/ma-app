import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class TrocarSenha extends StatefulWidget {
  const TrocarSenha({super.key});

  @override
  State<TrocarSenha> createState() => _TrocarSenhaState();
}

class _TrocarSenhaState extends State<TrocarSenha> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _salvando = false;
  bool _obscureSenhaAtual = true;
  bool _obscureNova = true;
  bool _obscureConfirmar = true;

  Future<void> _salvar() async {
    if (_senhaAtualController.text.isEmpty ||
        _novaSenhaController.text.isEmpty ||
        _confirmarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha todos os campos.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_novaSenhaController.text != _confirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('As senhas não coincidem.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_novaSenhaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A nova senha deve ter pelo menos 6 caracteres.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // Valida a senha atual fazendo login novamente
      final email = supabase.auth.currentUser?.email;
      if (email == null) throw Exception('Sessão expirada');

      await supabase.auth.signInWithPassword(
        email: email,
        password: _senhaAtualController.text,
      );

      // Atualiza para a nova senha
      await supabase.auth.updateUser(
        UserAttributes(password: _novaSenhaController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha atual incorreta. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trocar Senha'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF1E6B3C)),
            const SizedBox(height: 24),
            TextField(
              controller: _senhaAtualController,
              obscureText: _obscureSenhaAtual,
              decoration: InputDecoration(
                labelText: 'Senha atual',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureSenhaAtual
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _novaSenhaController,
              obscureText: _obscureNova,
              decoration: InputDecoration(
                labelText: 'Nova senha',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureNova ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNova = !_obscureNova),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmarController,
              obscureText: _obscureConfirmar,
              decoration: InputDecoration(
                labelText: 'Confirmar nova senha',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmar
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirmar = !_obscureConfirmar),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1E6B3C),
                foregroundColor: Colors.white,
              ),
              child: _salvando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
