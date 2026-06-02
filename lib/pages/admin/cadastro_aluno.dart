import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ma_app/pages/admin/form_cadastro_aluno.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

final supabase = Supabase.instance.client;

class CadastroAluno extends StatefulWidget {
  const CadastroAluno({super.key});

  @override
  State<CadastroAluno> createState() => _CadastroAlunoState();
}

class _CadastroAlunoState extends State<CadastroAluno> {
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _alunos = [];
  bool _carregando = true;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();

  String? _instituicaoSelecionada;
  String _turnoSelecionado = 'noturno';
  String _cursoController = '';
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final instituicoes = await supabase
          .from('instituicoes')
          .select('id, nome, cidade')
          .order('nome');

      final alunos = await supabase.from('estudantes').select('''
            id, curso, turno, pontos_penalidade,
            usuarios(id, nome_completo, email, status, cpf),
            instituicoes(nome)
          ''');

      setState(() {
        _instituicoes = List<Map<String, dynamic>>.from(instituicoes);
        _alunos = List<Map<String, dynamic>>.from(alunos);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  String _gerarSenha() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty ||
        _cpfController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _cursoController.isEmpty ||
        _instituicaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha todos os campos.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _salvando = true);
    final senhaGerada = _gerarSenha();

    try {
      final session = supabase.auth.currentSession;
      if (session == null) throw Exception('Sessão expirada');

      final response = await http.post(
        Uri.parse('http://192.168.1.29:8000/auth/criar-usuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'senha': senhaGerada,
          'nome_completo': _nomeController.text.trim(),
          'perfil': 'estudante',
        }),
      );

      if (response.statusCode != 200) {
        final erro = jsonDecode(response.body);
        throw Exception(erro['detail'] ?? 'Erro ao criar usuário');
      }

      final novoUsuario = jsonDecode(response.body);
      final usuarioId = novoUsuario['id'];

      await supabase
          .from('usuarios')
          .update({'cpf': _cpfController.text.trim()}).eq('id', usuarioId);

      final agora = DateTime.now();
      final validade = agora.month <= 6
          ? DateTime(agora.year, 12, 31)
          : DateTime(agora.year + 1, 6, 30);

      await supabase.from('estudantes').insert({
        'usuario_id': usuarioId,
        'instituicao_id': _instituicaoSelecionada,
        'curso': _cursoController,
        'turno': _turnoSelecionado,
        'validade_carteira': validade.toIso8601String().substring(0, 10),
        'contrato_assinado_em': null,
        'contrato_ip': null,
        'contrato_dispositivo': null,
      });

      await _carregarDados();

      if (mounted) {
        Navigator.pop(context);
        _mostrarSenhaGerada(
          _nomeController.text.trim(),
          _emailController.text.trim(),
          senhaGerada,
        );
      }

      _nomeController.clear();
      _cpfController.clear();
      _emailController.clear();
      setState(() {
        _cursoController = '';
        _instituicaoSelecionada = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  void _mostrarSenhaGerada(String nome, String email, String senha) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E6B3C), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1E6B3C)),
            SizedBox(width: 8),
            Text('Aluno cadastrado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: $nome',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Email: $email'),
            const SizedBox(height: 16),
            const Text('Senha temporária:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      senha,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: senha));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Senha copiada!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Anote e repasse ao aluno. Ele poderá trocar a senha no primeiro acesso.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6B3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK, anotei a senha'),
          ),
        ],
      ),
    );
  } // <- fechamento correto do _mostrarSenhaGerada

  Future<void> _confirmarDelete(
      Map<String, dynamic> aluno, Map<String, dynamic> usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Remover Aluno?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              usuario['nome_completo'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Isso removerá permanentemente o aluno, '
              'seu histórico de penalidades e confirmações.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // 1 — Remove do Supabase Auth PRIMEIRO via backend
      final session = supabase.auth.currentSession;
      if (session != null) {
        await http.delete(
          Uri.parse(
              'http://192.168.1.29:8000/auth/deletar-usuario/${usuario['id']}'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        );
      }

      // 2 — Remove confirmações
      await supabase
          .from('confirmacoes')
          .delete()
          .eq('estudante_id', aluno['id']);

      // 3 — Remove penalidades
      await supabase
          .from('penalidades')
          .delete()
          .eq('estudante_id', aluno['id']);

      // 4 — Remove o perfil de estudante
      await supabase.from('estudantes').delete().eq('id', aluno['id']);

      // 5 — Remove o usuário da tabela public.usuarios
      await supabase.from('usuarios').delete().eq('id', usuario['id']);

      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aluno removido com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao remover: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alunos'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormCadastroAluno()),
          );
          if (resultado != null) {
            await _carregarDados();
            _mostrarSenhaGerada(
              resultado['nome'],
              resultado['email'],
              resultado['senha'],
            );
          }
        },
        backgroundColor: const Color(0xFF1E6B3C),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Novo Aluno', style: TextStyle(color: Colors.white)),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _alunos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 72, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Nenhum aluno cadastrado.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: ListView.builder(
                    itemCount: _alunos.length,
                    itemBuilder: (context, i) {
                      final aluno = _alunos[i];
                      final usuario = aluno['usuarios'] as Map<String, dynamic>;
                      final inst =
                          aluno['instituicoes'] as Map<String, dynamic>?;
                      final ativo = usuario['status'] == 'ativo';
                      final pontos = aluno['pontos_penalidade'] as int;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              ativo ? const Color(0xFF1E6B3C) : Colors.grey,
                          child: Text(
                            usuario['nome_completo'][0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          usuario['nome_completo'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${aluno['curso']} • ${inst?['nome'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (pontos > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pontos >= 80
                                      ? Colors.red[100]
                                      : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pontos pts',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: pontos >= 80
                                        ? Colors.red
                                        : Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _confirmarDelete(aluno, usuario),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
