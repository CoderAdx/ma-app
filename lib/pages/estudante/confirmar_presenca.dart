import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ma_app/services/auth_service.dart';

final supabase = Supabase.instance.client;

class ConfirmarPresenca extends StatefulWidget {
  const ConfirmarPresenca({super.key});

  @override
  State<ConfirmarPresenca> createState() => _ConfirmarPresencaState();
}

class _ConfirmarPresencaState extends State<ConfirmarPresenca> {
  Map<String, dynamic>? _viagem;
  Map<String, dynamic>? _confirmacao;
  Map<String, dynamic>? _estudante;
  bool _carregando = true;
  bool _processando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final viagem = await supabase
          .from('viagens')
          .select('''
            id, status, data_viagem,
            horario_limite_confirmacao,
            horario_partida_volta,
            veiculos(placa, modelo, capacidade_assentos),
            paradas_viagem(ordem, instituicoes(nome, cidade))
          ''')
          .eq('data_viagem', DateTime.now().toIso8601String().substring(0, 10))
          .eq('status', 'aberta')
          .maybeSingle();

      print('VIAGEM: $viagem'); // <- debug

      final estudante = await AuthService.getPerfilEstudante();
      print('ESTUDANTE: $estudante'); // <- debug

      Map<String, dynamic>? confirmacao;
      if (viagem != null && estudante != null) {
        final result = await supabase
            .from('confirmacoes')
            .select('id, tipo, status_embarque, confirmado_em')
            .eq('viagem_id', viagem['id'])
            .eq('estudante_id', estudante['id'])
            .neq('status_embarque', 'cancelado')
            .maybeSingle();
        confirmacao = result;
        print('CONFIRMACAO: $confirmacao'); // <- debug
      }

      setState(() {
        _viagem = viagem;
        _estudante = estudante;
        _confirmacao = confirmacao;
        _carregando = false;
      });
    } catch (e, stack) {
      print('ERRO: $e'); // <- debug
      print('STACK: $stack'); // <- debug
      setState(() {
        _erro = 'Erro ao carregar viagem.';
        _carregando = false;
      });
    }
  }

  Future<void> _confirmar(String tipo) async {
    if (_viagem == null || _estudante == null) return;

    setState(() => _processando = true);

    try {
      // Verifica se já existe confirmação cancelada para reativar
      final existente = await supabase
          .from('confirmacoes')
          .select('id')
          .eq('viagem_id', _viagem!['id'])
          .eq('estudante_id', _estudante!['id'])
          .eq('tipo', tipo)
          .maybeSingle();

      if (existente != null) {
        // Reativa a confirmação cancelada
        await supabase.from('confirmacoes').update({
          'status_embarque': 'confirmado',
          'confirmado_em': DateTime.now().toIso8601String(),
        }).eq('id', existente['id']);
      } else {
        // Cria nova confirmação
        await supabase.from('confirmacoes').insert({
          'viagem_id': _viagem!['id'],
          'estudante_id': _estudante!['id'],
          'tipo': tipo,
          'status_embarque': 'confirmado',
        });
      }

      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Presença confirmada: ${_traduzirTipo(tipo)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().contains('LOTACAO_MAXIMA')
          ? 'Ônibus lotado! Você entrou na lista de espera.'
          : 'Erro ao confirmar. Tente novamente.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _processando = false);
    }
  }

  Future<void> _cancelar() async {
    if (_confirmacao == null) return;

    setState(() => _processando = true);

    try {
      await supabase.from('confirmacoes').update(
          {'status_embarque': 'cancelado'}).eq('id', _confirmacao!['id']);

      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presença cancelada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao cancelar.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _processando = false);
    }
  }

  Future<void> _confirmarEmbarque() async {
    if (_confirmacao == null) return;

    setState(() => _processando = true);

    try {
      await supabase.from('confirmacoes').update({
        'status_embarque': 'embarcado',
        'embarcado_em': DateTime.now().toIso8601String(),
      }).eq('id', _confirmacao!['id']);

      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Embarque confirmado! Boa viagem!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao confirmar embarque.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processando = false);
    }
  }

  String _traduzirTipo(String tipo) {
    switch (tipo) {
      case 'ida':
        return 'Só ida';
      case 'volta':
        return 'Só volta';
      case 'ida_e_volta':
        return 'Ida e volta';
      default:
        return tipo;
    }
  }

  bool _dentroDoHorario() {
    if (_viagem == null) return false;
    final limite = _viagem!['horario_limite_confirmacao'] as String;
    final partes = limite.split(':');
    final agora = TimeOfDay.now();
    final limiteHora = TimeOfDay(
      hour: int.parse(partes[0]),
      minute: int.parse(partes[1]),
    );
    return agora.hour < limiteHora.hour ||
        (agora.hour == limiteHora.hour && agora.minute < limiteHora.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Presença'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : _viagem == null
                  ? _buildSemViagem()
                  : _buildComViagem(),
    );
  }

  Widget _buildSemViagem() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined,
                size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma viagem disponível para hoje.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'O fiscal ainda não criou a viagem do dia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComViagem() {
    final veiculo = _viagem!['veiculos'] as Map<String, dynamic>;
    final paradas = _viagem!['paradas_viagem'] as List<dynamic>;
    final dentroHorario = _dentroDoHorario();
    final jaConfirmou =
        _confirmacao != null && _confirmacao!['status_embarque'] != 'cancelado';

    // Ordena as paradas
    paradas.sort((a, b) => (a['ordem'] as int).compareTo(b['ordem'] as int));

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card da viagem
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E6B3C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              veiculo['modelo'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            Text(
                              'Placa: ${veiculo['placa']} • ${veiculo['capacidade_assentos']} assentos',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  // Paradas
                  ...paradas.map((p) {
                    final inst = p['instituicoes'] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${p['ordem']}ª parada — ${inst['nome']}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Limite de confirmação: ${_viagem!['horario_limite_confirmacao']}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status da confirmação
            if (jaConfirmou) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Presença confirmada!',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          Text(
                            _traduzirTipo(_confirmacao!['tipo']),
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_confirmacao!['tipo'] != 'ida' &&
                  _confirmacao!['status_embarque'] == 'confirmado')
                ElevatedButton.icon(
                  onPressed: _processando ? null : _confirmarEmbarque,
                  icon: const Icon(Icons.directions_bus),
                  label: const Text('Confirmar Meu Embarque'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              if (_confirmacao!['status_embarque'] == 'embarcado')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Embarque confirmado!',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _processando ? null : _cancelar,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Cancelar Presença',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ] else if (!dentroHorario) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_off, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Horário limite de confirmação encerrado.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text('Como você vai viajar hoje?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBotaoConfirmacao(
                label: 'Ida e Volta',
                subtitulo: 'Maruim → Aracaju → Maruim',
                icone: Icons.swap_horiz,
                tipo: 'ida_e_volta',
                cor: const Color(0xFF1E6B3C),
              ),
              const SizedBox(height: 12),
              _buildBotaoConfirmacao(
                label: 'Só Ida',
                subtitulo: 'Maruim → Aracaju',
                icone: Icons.arrow_forward,
                tipo: 'ida',
                cor: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildBotaoConfirmacao(
                label: 'Só Volta',
                subtitulo: 'Aracaju → Maruim',
                icone: Icons.arrow_back,
                tipo: 'volta',
                cor: Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoConfirmacao({
    required String label,
    required String subtitulo,
    required IconData icone,
    required String tipo,
    required Color cor,
  }) {
    return ElevatedButton(
      onPressed: _processando ? null : () => _confirmar(tipo),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: cor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icone, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitulo,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          if (_processando)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          else
            const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
