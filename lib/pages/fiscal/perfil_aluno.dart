import 'package:flutter/material.dart';
import 'package:ma_app/pages/estudante/carteira_digital_fiscal.dart';

class PerfilAluno extends StatelessWidget {
  final Map<String, dynamic> estudante;
  const PerfilAluno({super.key, required this.estudante});

  @override
  Widget build(BuildContext context) {
    final usuario = estudante['usuarios'] as Map<String, dynamic>;
    final instituicao = estudante['instituicoes'] as Map<String, dynamic>?;
    final pontos = estudante['pontos_penalidade'] as int;
    final suspenso = usuario['status'] == 'suspenso';

    return Scaffold(
      appBar: AppBar(
        title: Text(usuario['nome_completo'].split(' ')[0]),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto e nome
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF1E6B3C),
                    backgroundImage: estudante['foto_url'] != null
                        ? NetworkImage(estudante['foto_url'])
                        : null,
                    child: estudante['foto_url'] == null
                        ? Text(
                            usuario['nome_completo'][0],
                            style: const TextStyle(
                                fontSize: 36, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario['nome_completo'],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (suspenso)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SUSPENSO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Informações
            _buildCard(children: [
              _buildInfo('CPF', usuario['cpf'] ?? 'Não informado'),
              _buildInfo('Instituição', instituicao?['nome'] ?? 'N/A'),
              _buildInfo('Curso', estudante['curso']),
              _buildInfo('Turno', (estudante['turno'] as String).toUpperCase()),
            ]),
            const SizedBox(height: 16),

            // Pontos de penalidade
            _buildCard(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pontos de Penalidade',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$pontos / 100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: pontos >= 80 ? Colors.red : Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: pontos / 100,
                backgroundColor: Colors.grey[200],
                color: pontos >= 80 ? Colors.red : Colors.orange,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
            const SizedBox(height: 24),

            // Botão carteira digital
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarteiraDigitalFiscal(
                      estudante: estudante, usuario: usuario),
                ),
              ),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Ver Carteira Digital'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1E6B3C),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Botão chat
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Enviar Mensagem'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
