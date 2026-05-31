import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ListaEmbarque extends StatefulWidget {
  final String viagemId;
  const ListaEmbarque({super.key, required this.viagemId});

  @override
  State<ListaEmbarque> createState() => _ListaEmbarqueState();
}

class _ListaEmbarqueState extends State<ListaEmbarque>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _ida = [];
  List<Map<String, dynamic>> _volta = [];
  bool _carregando = true;
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarConfirmacoes();
  }

  Future<void> _carregarConfirmacoes() async {
    try {
      final confirmacoes = await supabase
          .from('confirmacoes')
          .select('''
            id, tipo, status_embarque, confirmado_em, embarcado_em,
            estudantes(
              id,
              usuarios(nome_completo),
              instituicoes(nome)
            )
          ''')
          .eq('viagem_id', widget.viagemId)
          .neq('status_embarque', 'cancelado')
          .order('confirmado_em');

      final ida = <Map<String, dynamic>>[];
      final volta = <Map<String, dynamic>>[];

      for (final c in confirmacoes) {
        final tipo = c['tipo'] as String;
        if (tipo == 'ida' || tipo == 'ida_e_volta') ida.add(c);
        if (tipo == 'volta' || tipo == 'ida_e_volta') volta.add(c);
      }

      setState(() {
        _ida = ida;
        _volta = volta;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _confirmarEmbarque(String confirmacaoId) async {
    try {
      await supabase.from('confirmacoes').update({
        'status_embarque': 'embarcado',
        'embarcado_em': DateTime.now().toIso8601String(),
      }).eq('id', confirmacaoId);

      await _carregarConfirmacoes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Embarque confirmado!'),
            backgroundColor: Colors.green,
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
    }
  }

  Future<void> _verificarFaltantes() async {
    setState(() => _verificando = true);

    try {
      // Chama o endpoint do FastAPI que cruza confirmados vs embarcados
      // e dispara o alerta Realtime se houver faltantes
      final faltantes = _volta
          .where((c) => c['status_embarque'] != 'embarcado')
          .map((c) => c['estudantes']['usuarios']['nome_completo'] as String)
          .toList();

      if (faltantes.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Tudo certo!'),
                ],
              ),
              content: const Text(
                  'Todos os passageiros embarcaram. O ônibus pode partir!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _buildPopupVermelho(faltantes),
          );
        }
      }
    } finally {
      setState(() => _verificando = false);
    }
  }

  Widget _buildPopupVermelho(List<String> faltantes) {
    return AlertDialog(
      backgroundColor: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ATENÇÃO — FALTANTES!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${faltantes.length} passageiro(s) confirmaram volta mas não embarcaram:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...faltantes.map((nome) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_off, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nome,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          const Text(
            'Não parta antes de localizar esses passageiros!',
            style: TextStyle(
                color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Embarque'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Ida (${_ida.length})'),
            Tab(text: 'Volta (${_volta.length})'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista(_ida, mostrarEmbarque: false),
                      _buildLista(_volta, mostrarEmbarque: true),
                    ],
                  ),
                ),

                // Botão verificar faltantes — só na aba volta
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    if (_tabController.index != 1) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _verificando ? null : _verificarFaltantes,
                        icon: _verificando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.warning_amber_rounded),
                        label: const Text('Verificar Faltantes'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> lista,
      {required bool mostrarEmbarque}) {
    if (lista.isEmpty) {
      return const Center(
        child: Text('Nenhum passageiro confirmado.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarConfirmacoes,
      child: ListView.builder(
        itemCount: lista.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, i) {
          final c = lista[i];
          final estudante = c['estudantes'] as Map<String, dynamic>;
          final nome = estudante['usuarios']['nome_completo'] as String;
          final inst = estudante['instituicoes']?['nome'] ?? '';
          final embarcado = c['status_embarque'] == 'embarcado';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  embarcado ? Colors.green : const Color(0xFF1E6B3C),
              child: Icon(
                embarcado ? Icons.check : Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              nome,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: embarcado ? TextDecoration.none : null,
              ),
            ),
            subtitle: Text(inst, style: const TextStyle(fontSize: 12)),
            trailing: mostrarEmbarque
                ? embarcado
                    ? const Chip(
                        label: Text('Embarcou',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.zero,
                      )
                    : ElevatedButton(
                        onPressed: () => _confirmarEmbarque(c['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E6B3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Embarcar',
                            style: TextStyle(fontSize: 12)),
                      )
                : null,
          );
        },
      ),
    );
  }
}
