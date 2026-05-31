import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/pages/estudante/carteira_digital.dart';
import 'package:ma_app/pages/estudante/confirmar_presenca.dart';
import 'package:ma_app/pages/estudante/minhas_penalidades.dart';
import 'package:ma_app/widgets/alerta_realtime.dart';

class EstudanteHome extends StatelessWidget {
  final Map<String, dynamic> usuario;
  const EstudanteHome({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final suspenso = usuario['status'] == 'suspenso';

    // ID da viagem do dia — depois vamos buscar dinamicamente
    const viagemId = 'ae624368-a98d-4df2-b1a9-7426449dd28a';

    return AlertaRealtimeWrapper(
      viagemId: viagemId,
      child: Scaffold(
        backgroundColor: suspenso ? Colors.grey[300] : null,
        appBar: AppBar(
          title: const Text('Maruim Acadêmico'),
          backgroundColor: const Color(0xFF1E6B3C),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService.logout(),
            )
          ],
        ),
        body: AbsorbPointer(
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
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: suspenso
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ConfirmarPresenca()),
                          ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar Presença'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1E6B3C),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarteiraDigital()),
                  ),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Minha Carteira Digital'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MinhasPenalidades()),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Minhas Penalidades'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
