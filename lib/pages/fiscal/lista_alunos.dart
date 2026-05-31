import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ma_app/pages/fiscal/perfil_aluno.dart';

final supabase = Supabase.instance.client;

class ListaAlunos extends StatefulWidget {
  final String? viagemId;
  const ListaAlunos({super.key, this.viagemId});

  @override
  State<ListaAlunos> createState() => _ListaAlunosState();
}

class _ListaAlunosState extends State<ListaAlunos>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _todosAlunos = [];
  List<Map<String, dynamic>> _alunosDoDia = [];
  bool _carregando = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      // Busca todos os estudantes
      final todos = await supabase.from('estudantes').select('''
        id, curso, turno, pontos_penalidade, foto_url,
        usuarios(id, nome_completo, status, cpf),
        instituicoes(nome)
      ''');

      // Busca confirmados da viagem do dia se tiver viagemId
      List<Map<String, dynamic>> doDia = [];
      if (widget.viagemId != null) {
        final confirmados = await supabase
            .from('confirmacoes')
            .select('''
              tipo, status_embarque,
              estudantes(
                id, curso, turno, pontos_penalidade, foto_url,
                usuarios(id, nome_completo, status, cpf),
                instituicoes(nome)
              )
            ''')
            .eq('viagem_id', widget.viagemId!)
            .neq('status_embarque', 'cancelado');

        doDia = confirmados
            .map((c) => {
                  ...c['estudantes'] as Map<String, dynamic>,
                  'tipo_confirmacao': c['tipo'],
                  'status_embarque': c['status_embarque'],
                })
            .toList();
      }

      setState(() {
        _todosAlunos = List<Map<String, dynamic>>.from(todos);
        _alunosDoDia = doDia;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> lista) {
    if (_busca.isEmpty) return lista;
    return lista.where((a) {
      final nome = (a['usuarios']['nome_completo'] as String).toLowerCase();
      return nome.contains(_busca.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alunos'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'Todos'),
            Tab(text: 'Viagem do Dia (${_alunosDoDia.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: InputDecoration(
                hintText: 'Buscar aluno...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Abas
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLista(_filtrar(_todosAlunos)),
                      widget.viagemId == null
                          ? const Center(
                              child: Text(
                                'Nenhuma viagem ativa hoje.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : _buildLista(_filtrar(_alunosDoDia),
                              mostrarEmbarque: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> lista,
      {bool mostrarEmbarque = false}) {
    if (lista.isEmpty) {
      return const Center(
        child: Text('Nenhum aluno encontrado.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.builder(
        itemCount: lista.length,
        itemBuilder: (context, i) {
          final aluno = lista[i];
          final usuario = aluno['usuarios'] as Map<String, dynamic>;
          final suspenso = usuario['status'] == 'suspenso';
          final pontos = aluno['pontos_penalidade'] as int;

          return ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilAluno(estudante: aluno),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor:
                  suspenso ? Colors.red[100] : const Color(0xFF1E6B3C),
              backgroundImage: aluno['foto_url'] != null
                  ? NetworkImage(aluno['foto_url'])
                  : null,
              child: aluno['foto_url'] == null
                  ? Text(
                      usuario['nome_completo'][0],
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Text(
              usuario['nome_completo'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: suspenso ? Colors.red : null,
              ),
            ),
            subtitle: Text(
              '${aluno['curso']} • ${(aluno['turno'] as String).toUpperCase()}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (suspenso)
                  const Icon(Icons.block, color: Colors.red, size: 16),
                if (pontos > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          pontos >= 80 ? Colors.red[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pontos pts',
                      style: TextStyle(
                        fontSize: 11,
                        color: pontos >= 80 ? Colors.red : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (mostrarEmbarque) ...[
                  const SizedBox(width: 8),
                  Icon(
                    aluno['status_embarque'] == 'embarcado'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: aluno['status_embarque'] == 'embarcado'
                        ? Colors.green
                        : Colors.grey,
                  ),
                ],
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
  }
}
