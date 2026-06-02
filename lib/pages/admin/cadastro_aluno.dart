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
            usuarios(nome_completo, email, status, cpf),
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

      // Cria o usuário no Auth via backend
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

      // Atualiza o CPF na tabela usuarios
      await supabase
          .from('usuarios')
          .update({'cpf': _cpfController.text.trim()}).eq('id', usuarioId);

      // Calcula validade — fim do semestre atual
      final agora = DateTime.now();
      final validade = agora.month <= 6
          ? DateTime(agora.year, 12, 31)
          : DateTime(agora.year + 1, 6, 30);

      // Cria o perfil de estudante
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
  }

  void _mostrarFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Cadastrar Aluno',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Uma senha temporária será gerada automaticamente.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: '000.000.000-00',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => _cursoController = v,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Curso',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _turnoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Turno',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'matutino', child: Text('Matutino')),
                    DropdownMenuItem(
                        value: 'vespertino', child: Text('Vespertino')),
                    DropdownMenuItem(value: 'noturno', child: Text('Noturno')),
                  ],
                  onChanged: (v) => setModalState(() => _turnoSelecionado = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _instituicaoSelecionada,
                  hint: const Text('Selecione a instituição'),
                  decoration: const InputDecoration(
                    labelText: 'Instituição',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: _instituicoes.isEmpty
                      ? [
                          const DropdownMenuItem(
                              value: '', child: Text('Carregando...'))
                        ]
                      : _instituicoes.map((inst) {
                          return DropdownMenuItem<String>(
                            value: inst['id'] as String,
                            child: Text(
                              '${inst['nome']} - ${inst['cidade']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                  onChanged: _instituicoes.isEmpty
                      ? null
                      : (v) {
                          setModalState(() => _instituicaoSelecionada = v);
                          setState(() => _instituicaoSelecionada = v);
                        },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.person_add),
                  label: const Text('Cadastrar Aluno'),
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
      ),
    );
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
                        trailing: pontos > 0
                            ? Container(
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
                              )
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
