import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/services/viagem_service.dart';
import 'package:ma_app/pages/fiscal/lista_alunos.dart';
import 'package:ma_app/pages/fiscal/lista_embarque.dart';
import 'package:ma_app/pages/fiscal/aplicar_penalidade.dart';
import 'package:ma_app/pages/chat/lista_contatos.dart';

class OperadorHome extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const OperadorHome({super.key, required this.usuario});

  @override
  State<OperadorHome> createState() => _OperadorHomeState();
}

class _OperadorHomeState extends State<OperadorHome> {
  Map<String, dynamic>? _viagemHoje;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarViagem();
  }

  Future<void> _carregarViagem() async {
    final viagem = await ViagemService.getViagemHoje();
    setState(() {
      _viagemHoje = viagem;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfil =
        widget.usuario['perfil'] == 'motorista' ? 'Motorista' : 'Monitor';
    final isMonitor = widget.usuario['perfil'] == 'monitor';

    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do $perfil'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(),
          )
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarViagem,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Olá, ${widget.usuario['nome_completo'].split(' ')[0]}!',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Status da viagem
                    if (_viagemHoje != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Viagem ativa — ${_viagemHoje!['veiculos']['placa']}',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Nenhuma viagem hoje.',
                                style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Lista de passageiros
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ListaAlunos(viagemId: _viagemHoje?['id']),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Ver Lista de Passageiros'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E6B3C),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de embarque
                    ElevatedButton.icon(
                      onPressed: _viagemHoje == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ListaEmbarque(
                                      viagemId: _viagemHoje!['id']),
                                ),
                              ),
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Lista de Embarque'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E6B3C),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sugerir penalidade — só monitor
                    if (isMonitor)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AplicarPenalidade()),
                        ),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('Sugerir Penalidade'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (isMonitor) const SizedBox(height: 16),

                    // Mensagens
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
    );
  }
}
