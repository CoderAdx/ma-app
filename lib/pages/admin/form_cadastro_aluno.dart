import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

final supabase = Supabase.instance.client;

class FormCadastroAluno extends StatefulWidget {
  const FormCadastroAluno({super.key});

  @override
  State<FormCadastroAluno> createState() => _FormCadastroAlunoState();
}

class _FormCadastroAlunoState extends State<FormCadastroAluno> {
  List<Map<String, dynamic>> _instituicoes = [];
  bool _carregando = true;
  bool _salvando = false;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _cursoController = TextEditingController();

  String? _instituicaoSelecionada;
  String _turnoSelecionado = 'noturno';

  @override
  void initState() {
    super.initState();
    _carregarInstituicoes();
  }

  Future<void> _carregarInstituicoes() async {
    final instituicoes = await supabase
        .from('instituicoes')
        .select('id, nome, cidade')
        .order('nome');

    setState(() {
      _instituicoes = List<Map<String, dynamic>>.from(instituicoes);
      _carregando = false;
    });
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
        _cursoController.text.isEmpty ||
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
        'curso': _cursoController.text.trim(),
        'turno': _turnoSelecionado,
        'validade_carteira': validade.toIso8601String().substring(0, 10),
        'contrato_assinado_em': null,
        'contrato_ip': null,
        'contrato_dispositivo': null,
      });

      if (mounted) {
        // Volta para a lista e mostra a senha
        Navigator.pop(context, {
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'senha': senhaGerada,
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Aluno'),
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
                  const Text(
                    'Uma senha temporária será gerada automaticamente.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
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
                    controller: _cursoController,
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
                      DropdownMenuItem(
                          value: 'noturno', child: Text('Noturno')),
                    ],
                    onChanged: (v) => setState(() => _turnoSelecionado = v!),
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
                    items: _instituicoes.map((inst) {
                      return DropdownMenuItem<String>(
                        value: inst['id'] as String,
                        child: Text(
                          '${inst['nome']} — ${inst['cidade']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _instituicaoSelecionada = v),
                  ),
                  const SizedBox(height: 32),
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
                    label: const Text('Cadastrar Aluno',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1E6B3C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
