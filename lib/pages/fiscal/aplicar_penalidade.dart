import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Infrações pré-definidas com pontuação
const _infracoes = [
  {'descricao': 'Faltou sem cancelar a vaga', 'pontos': 30},
  {'descricao': 'Cancelou fora do prazo', 'pontos': 20},
  {'descricao': 'Comportamento inadequado no veículo', 'pontos': 40},
  {'descricao': 'Uso indevido da carteira', 'pontos': 50},
  {'descricao': 'Reincidência', 'pontos': 30},
  {'descricao': 'Outra infração', 'pontos': 0},
];

class AplicarPenalidade extends StatefulWidget {
  const AplicarPenalidade({super.key});

  @override
  State<AplicarPenalidade> createState() => _AplicarPenalidadeState();
}

class _AplicarPenalidadeState extends State<AplicarPenalidade> {
  List<Map<String, dynamic>> _estudantes = [];
  bool _carregando = true;
  bool _aplicando = false;
  String _busca = '';

  Map<String, dynamic>? _estudanteSelecionado;
  Map<String, dynamic>? _infracaoSelecionada;
  final _descricaoController = TextEditingController();
  final _pontosController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarEstudantes();
  }

  Future<void> _carregarEstudantes() async {
    try {
      final estudantes = await supabase.from('estudantes').select('''
            id, curso, pontos_penalidade,
            usuarios(id, nome_completo, status)
          ''');

      setState(() {
        _estudantes = List<Map<String, dynamic>>.from(estudantes);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _aplicar() async {
    if (_estudanteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione um estudante.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_infracaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione uma infração.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final descricao = _infracaoSelecionada!['descricao'] == 'Outra infração'
        ? _descricaoController.text.trim()
        : _infracaoSelecionada!['descricao'] as String;

    final pontos = _infracaoSelecionada!['descricao'] == 'Outra infração'
        ? int.tryParse(_pontosController.text) ?? 0
        : _infracaoSelecionada!['pontos'] as int;

    if (descricao.isEmpty || pontos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha a descrição e os pontos.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _aplicando = true);

    try {
      final fiscal = await supabase.auth.getUser();

      await supabase.from('penalidades').insert({
        'estudante_id': _estudanteSelecionado!['id'],
        'aplicado_por': fiscal.user!.id,
        'descricao': descricao,
        'pontos': pontos,
        'status': 'aprovada',
      });

      // Recarrega os dados para atualizar pontos
      await Future.delayed(const Duration(milliseconds: 800));
      await _carregarEstudantes();

      if (mounted) {
        // Mostra resultado
        final estudanteAtualizado = _estudantes
            .firstWhere((e) => e['id'] == _estudanteSelecionado!['id']);
        final novoPontos = estudanteAtualizado['pontos_penalidade'] as int;
        final suspenso = novoPontos >= 100;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: suspenso ? Colors.red : Colors.orange,
                width: 2,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  suspenso ? Icons.block : Icons.warning_amber_rounded,
                  color: suspenso ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(suspenso ? 'Aluno Suspenso!' : 'Penalidade Aplicada!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estudanteSelecionado!['usuarios']['nome_completo'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Infração: $descricao'),
                Text('Pontos aplicados: +$pontos'),
                const SizedBox(height: 8),
                Text(
                  'Total acumulado: $novoPontos / 100',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: suspenso ? Colors.red : Colors.orange,
                  ),
                ),
                if (suspenso) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'O aluno foi suspenso automaticamente por 3 dias.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Limpa seleção para nova penalidade
                  setState(() {
                    _estudanteSelecionado = null;
                    _infracaoSelecionada = null;
                    _descricaoController.clear();
                    _pontosController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      suspenso ? Colors.red : const Color(0xFF1E6B3C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _aplicando = false);
    }
  }

  List<Map<String, dynamic>> get _estudantesFiltrados {
    if (_busca.isEmpty) return _estudantes;
    return _estudantes.where((e) {
      final nome = (e['usuarios']['nome_completo'] as String).toLowerCase();
      return nome.contains(_busca.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicar Penalidade'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Seção 1: Selecionar estudante
                  _buildSecao('1. Selecionar Estudante', Icons.person),
                  const SizedBox(height: 12),

                  // Busca
                  TextField(
                    onChanged: (v) => setState(() => _busca = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lista de estudantes
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _estudantesFiltrados.length,
                      itemBuilder: (context, i) {
                        final e = _estudantesFiltrados[i];
                        final usuario = e['usuarios'] as Map<String, dynamic>;
                        final selecionado =
                            _estudanteSelecionado?['id'] == e['id'];
                        final pontos = e['pontos_penalidade'] as int;

                        return ListTile(
                          onTap: () =>
                              setState(() => _estudanteSelecionado = e),
                          selected: selecionado,
                          selectedTileColor: Colors.orange.withOpacity(0.1),
                          leading: CircleAvatar(
                            backgroundColor: selecionado
                                ? Colors.orange
                                : const Color(0xFF1E6B3C),
                            child: Text(
                              usuario['nome_completo'][0],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(usuario['nome_completo'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${e['curso']} • $pontos pts'),
                          trailing: selecionado
                              ? const Icon(Icons.check_circle,
                                  color: Colors.orange)
                              : null,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seção 2: Selecionar infração
                  _buildSecao('2. Selecionar Infração', Icons.gavel),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _infracoes.map((inf) {
                      final selecionada = _infracaoSelecionada?['descricao'] ==
                          inf['descricao'];
                      return GestureDetector(
                        onTap: () => setState(() => _infracaoSelecionada = inf),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                selecionada ? Colors.orange : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selecionada
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            '${inf['descricao']} ${inf['pontos'] != 0 ? '(${inf['pontos']} pts)' : ''}',
                            style: TextStyle(
                              color:
                                  selecionada ? Colors.white : Colors.black87,
                              fontWeight: selecionada
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Campos extras para "Outra infração"
                  if (_infracaoSelecionada?['descricao'] ==
                      'Outra infração') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição da infração',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pontosController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pontos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botão aplicar
                  ElevatedButton.icon(
                    onPressed: _aplicando ? null : _aplicar,
                    icon: _aplicando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.gavel),
                    label: const Text('Aplicar Penalidade',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecao(String titulo, IconData icone) {
    return Row(
      children: [
        Icon(icone, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
