import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/services/viagem_service.dart';
import 'package:ma_app/pages/fiscal/criar_viagem.dart';
import 'package:ma_app/pages/fiscal/lista_alunos.dart';
import 'package:ma_app/pages/fiscal/lista_embarque.dart';

class FiscalHome extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const FiscalHome({super.key, required this.usuario});

  @override
  State<FiscalHome> createState() => _FiscalHomeState();
}

class _FiscalHomeState extends State<FiscalHome> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Fiscal'),
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

                    // Status da viagem do dia
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
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Viagem do dia criada — ${_viagemHoje!['veiculos']['placa']}',
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
                            Expanded(
                              child: Text(
                                'Nenhuma viagem criada para hoje.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final criou = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CriarViagem()),
                        );
                        if (criou == true) _carregarViagem();
                      },
                      icon: const Icon(Icons.add_road),
                      label: Text(_viagemHoje == null
                          ? 'Criar Viagem do Dia'
                          : 'Nova Viagem'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E6B3C),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text('Aplicar Penalidade'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListaAlunos(
                            viagemId: _viagemHoje?['id'], // <- dinâmico
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.people_alt_outlined),
                      label: const Text('Lista de Alunos'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E6B3C),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _viagemHoje == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ListaEmbarque(
                                    viagemId: _viagemHoje!['id'], // <- dinâmico
                                  ),
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
                  ],
                ),
              ),
            ),
    );
  }
}
