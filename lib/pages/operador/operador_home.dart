import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';

class OperadorHome extends StatelessWidget {
  final Map<String, dynamic> usuario;
  const OperadorHome({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final perfil = usuario['perfil'] == 'motorista' ? 'Motorista' : 'Monitor';

    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do $perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Olá, ${usuario['nome_completo'].split(' ')[0]}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.list_alt),
              label: const Text('Ver Lista de Passageiros'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Confirmar Embarque'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
