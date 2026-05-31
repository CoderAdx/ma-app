import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CriarViagem extends StatefulWidget {
  const CriarViagem({super.key});

  @override
  State<CriarViagem> createState() => _CriarViagemState();
}

class _CriarViagemState extends State<CriarViagem> {
  List<Map<String, dynamic>> _veiculos = [];
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _paradasSelecionadas = [];

  String? _veiculoSelecionado;
  String _horarioLimite = '15:00';
  String _horarioPartida = '22:30';
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final veiculos = await supabase
          .from('veiculos')
          .select('id, placa, modelo, capacidade_assentos')
          .eq('status', 'ativo');

      final instituicoes = await supabase
          .from('instituicoes')
          .select('id, nome, cidade')
          .order('nome');

      setState(() {
        _veiculos = List<Map<String, dynamic>>.from(veiculos);
        _instituicoes = List<Map<String, dynamic>>.from(instituicoes);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _adicionarParada(Map<String, dynamic> instituicao) {
    final jaAdicionada =
        _paradasSelecionadas.any((p) => p['id'] == instituicao['id']);

    if (jaAdicionada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instituição já adicionada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _paradasSelecionadas.add(instituicao));
  }

  void _removerParada(int index) {
    setState(() => _paradasSelecionadas.removeAt(index));
  }

  void _reordenarParadas(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _paradasSelecionadas.removeAt(oldIndex);
      _paradasSelecionadas.insert(newIndex, item);
    });
  }

  Future<void> _salvarViagem() async {
    if (_veiculoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um veículo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paradasSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma parada.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // Busca o ID do fiscal logado
      final usuario = await supabase.auth.getUser();
      final fiscalId = usuario.user!.id;

      // Cria a viagem
      final viagem = await supabase
          .from('viagens')
          .insert({
            'veiculo_id': _veiculoSelecionado,
            'fiscal_id': fiscalId,
            'horario_limite_confirmacao': _horarioLimite,
            'horario_partida_volta': _horarioPartida,
            'status': 'aberta',
          })
          .select()
          .single();

      // Cria as paradas na ordem
      for (int i = 0; i < _paradasSelecionadas.length; i++) {
        await supabase.from('paradas_viagem').insert({
          'viagem_id': viagem['id'],
          'instituicao_id': _paradasSelecionadas[i]['id'],
          'ordem': i + 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // retorna true para recarregar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar viagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarHorario(bool isLimite) async {
    final inicial = isLimite ? _horarioLimite : _horarioPartida;
    final partes = inicial.split(':');

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      ),
    );

    if (picked != null) {
      final horario =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isLimite) {
          _horarioLimite = horario;
        } else {
          _horarioPartida = horario;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Viagem do Dia'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Seção veículo
                  _buildSecao('Veículo', Icons.directions_bus),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _veiculoSelecionado,
                    hint: const Text('Selecione o veículo'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: _veiculos.map((v) {
                      return DropdownMenuItem<String>(
                        value: v['id'],
                        child: Text(
                          '${v['placa']} — ${v['modelo']} (${v['capacidade_assentos']} assentos)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _veiculoSelecionado = v),
                  ),
                  const SizedBox(height: 24),

                  // Seção horários
                  _buildSecao('Horários', Icons.access_time),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBotaoHorario(
                          label: 'Limite confirmação',
                          horario: _horarioLimite,
                          onTap: () => _selecionarHorario(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBotaoHorario(
                          label: 'Partida volta',
                          horario: _horarioPartida,
                          onTap: () => _selecionarHorario(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Seção paradas
                  _buildSecao('Paradas da Rota', Icons.location_on),
                  const SizedBox(height: 4),
                  const Text(
                    'Arraste para reordenar',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Lista de paradas selecionadas (reordenável)
                  if (_paradasSelecionadas.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paradasSelecionadas.length,
                      onReorder: _reordenarParadas,
                      itemBuilder: (context, i) {
                        final p = _paradasSelecionadas[i];
                        return ListTile(
                          key: ValueKey(p['id']),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E6B3C),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(p['nome']),
                          subtitle: Text(p['cidade']),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => _removerParada(i),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 12),

                  // Botões de instituições disponíveis
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _instituicoes.map((inst) {
                      final adicionada = _paradasSelecionadas
                          .any((p) => p['id'] == inst['id']);
                      return FilterChip(
                        label: Text(inst['nome']),
                        selected: adicionada,
                        onSelected: (_) => _adicionarParada(inst),
                        selectedColor: const Color(0xFF1E6B3C).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1E6B3C),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Botão salvar
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvarViagem,
                    icon: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Criar Viagem',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1E6B3C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
        Icon(icone, color: const Color(0xFF1E6B3C), size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoHorario({
    required String label,
    required String horario,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF1E6B3C)),
                const SizedBox(width: 4),
                Text(
                  horario,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E6B3C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
