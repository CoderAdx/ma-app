import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/services/viagem_service.dart';
import 'package:ma_app/pages/estudante/carteira_digital.dart';
import 'package:ma_app/pages/estudante/confirmar_presenca.dart';
import 'package:ma_app/pages/estudante/minhas_penalidades.dart';
import 'package:ma_app/widgets/alerta_realtime.dart';
import 'package:ma_app/pages/estudante/trocar_senha.dart';
import 'package:ma_app/pages/estudante/editar_perfil.dart';
import 'package:ma_app/pages/chat/lista_contatos.dart';

class EstudanteHome extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const EstudanteHome({super.key, required this.usuario});

  @override
  State<EstudanteHome> createState() => _EstudanteHomeState();
}

class _EstudanteHomeState extends State<EstudanteHome> {
  String? _viagemId;

  @override
  void initState() {
    super.initState();
    _carregarViagem();
  }

  Future<void> _carregarViagem() async {
    final viagem = await ViagemService.getViagemHoje();
    setState(() => _viagemId = viagem?['id']);
  }

  @override
  Widget build(BuildContext context) {
    final suspenso = widget.usuario['status'] == 'suspenso';

    return AlertaRealtimeWrapper(
      viagemId: _viagemId ?? 'sem-viagem',
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
                  'Olá, ${widget.usuario['nome_completo'].split(' ')[0]}!',
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
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrocarSenha()),
                  ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Trocar Senha'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final atualizou = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditarPerfil()),
                    );
                    if (atualizou == true) {
                      // Recarrega a viagem para atualizar o cache da carteira
                      _carregarViagem();
                    }
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Atualizar Foto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListaContatos(usuarioAtual: widget.usuario),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Mensagens'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1E6B3C),
                    foregroundColor: Colors.white,
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
