import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/services/viagem_service.dart';
import 'package:ma_app/pages/admin/cadastro_veiculo.dart';
import 'package:ma_app/pages/admin/cadastro_instituicao.dart';
import 'package:ma_app/pages/admin/cadastro_usuario.dart';
import 'package:ma_app/pages/fiscal/criar_viagem.dart';
import 'package:ma_app/pages/fiscal/lista_alunos.dart';
import 'package:ma_app/pages/fiscal/lista_embarque.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminHome extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const AdminHome({super.key, required this.usuario});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Map<String, dynamic>? _viagemHoje;
  Map<String, dynamic>? _resumo;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final viagem = await ViagemService.getViagemHoje();

      // Resumo geral do sistema
      final totalAlunos = await supabase.from('estudantes').select('id');

      final totalVeiculos =
          await supabase.from('veiculos').select('id').eq('status', 'ativo');

      final totalInstituicoes =
          await supabase.from('instituicoes').select('id');

      final suspensos =
          await supabase.from('usuarios').select('id').eq('status', 'suspenso');

      setState(() {
        _viagemHoje = viagem;
        _resumo = {
          'alunos': totalAlunos.length,
          'veiculos': totalVeiculos.length,
          'instituicoes': totalInstituicoes.length,
          'suspensos': suspensos.length,
        };
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
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
              onRefresh: _carregarDados,
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
                    const SizedBox(height: 4),
                    Text(
                      'Prefeitura Municipal de Maruim',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Cards de resumo
                    if (_resumo != null) ...[
                      Row(
                        children: [
                          _buildResumoCard('Alunos', _resumo!['alunos'],
                              Icons.school, Colors.blue),
                          const SizedBox(width: 12),
                          _buildResumoCard('Veículos', _resumo!['veiculos'],
                              Icons.directions_bus, const Color(0xFF1E6B3C)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildResumoCard(
                              'Instituições',
                              _resumo!['instituicoes'],
                              Icons.account_balance,
                              Colors.purple),
                          const SizedBox(width: 12),
                          _buildResumoCard('Suspensos', _resumo!['suspensos'],
                              Icons.block, Colors.red),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Status viagem do dia
                    _viagemHoje != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Viagem do dia ativa — ${_viagemHoje!['veiculos']['placa']}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
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

                    // Seção operacional
                    _buildSecao('Operacional', Icons.directions_bus),
                    const SizedBox(height: 12),
                    _buildBotao(
                      label: 'Criar Viagem do Dia',
                      icone: Icons.add_road,
                      cor: const Color(0xFF1E6B3C),
                      onTap: () async {
                        final criou = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CriarViagem()),
                        );
                        if (criou == true) _carregarDados();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildBotao(
                      label: 'Lista de Alunos',
                      icone: Icons.people_alt_outlined,
                      cor: const Color(0xFF1E6B3C),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ListaAlunos(viagemId: _viagemHoje?['id']),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBotao(
                      label: 'Lista de Embarque',
                      icone: Icons.how_to_reg,
                      cor: const Color(0xFF1E6B3C),
                      onTap: _viagemHoje == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ListaEmbarque(
                                      viagemId: _viagemHoje!['id']),
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),

                    // Seção cadastros
                    _buildSecao('Cadastros', Icons.settings),
                    const SizedBox(height: 12),
                    _buildBotao(
                      label: 'Gerenciar Veículos',
                      icone: Icons.directions_bus_filled,
                      cor: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroVeiculo()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBotao(
                      label: 'Gerenciar Instituições',
                      icone: Icons.account_balance,
                      cor: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroInstituicao()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBotao(
                      label: 'Gerenciar Usuários',
                      icone: Icons.manage_accounts,
                      cor: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CadastroUsuario()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumoCard(String label, int valor, IconData icone, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 24),
            const SizedBox(height: 8),
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
        Text(titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBotao({
    required String label,
    required IconData icone,
    required Color cor,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icone),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: cor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
      ),
    );
  }
}
