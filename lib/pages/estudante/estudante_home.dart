import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/pages/estudante/carteira_digital.dart';

class EstudanteHome extends StatelessWidget {
  final Map<String, dynamic> usuario;
  const EstudanteHome({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final suspenso = usuario['status'] == 'suspenso';

    return Scaffold(
      backgroundColor: suspenso ? Colors.grey[300] : null,
      appBar: AppBar(
        title: const Text('Maruim Acadêmico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(),
          )
        ],
      ),
      body: AbsorbPointer(
        // Se suspenso: bloqueia todos os toques na tela
        absorbing: suspenso,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (suspenso)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conta suspensa. Você não pode reservar vagas.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Olá, ${usuario['nome_completo'].split(' ')[0]}!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              // Botões de ação — desabilitados se suspenso
              ElevatedButton.icon(
                onPressed: suspenso ? null : () {},
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar Presença'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarteiraDigital()),
                  );
                },
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Minha Carteira Digital'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
