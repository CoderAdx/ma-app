import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

final supabase = Supabase.instance.client;

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _carregando = true;
  String _filtro = 'todos';

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  String _perfilSelecionado = 'fiscal';

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    try {
      List<Map<String, dynamic>> usuarios;

      if (_filtro != 'todos') {
        usuarios = await supabase
            .from('usuarios')
            .select('id, nome_completo, email, perfil, status')
            .eq('perfil', _filtro);
      } else {
        usuarios = await supabase
            .from('usuarios')
            .select('id, nome_completo, email, perfil, status');
      }

      print('FILTRO: $_filtro');
      print('TOTAL: ${usuarios.length}');
      print('DADOS: $usuarios');

      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(usuarios);
        _carregando = false;
      });
    } catch (e) {
      print('ERRO: $e');
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha todos os campos.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Cria no Supabase Auth — o trigger sincroniza com public.usuarios
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
          'senha': _senhaController.text.trim(),
          'nome_completo': _nomeController.text.trim(),
          'perfil': _perfilSelecionado,
        }),
      );

      if (response.statusCode == 200) {
        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();

        await _carregarUsuarios();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário criado!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final erro = jsonDecode(response.body);
        throw Exception(erro['detail'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _alterarStatus(String id, String statusAtual) async {
    final novoStatus = statusAtual == 'ativo' ? 'inativo' : 'ativo';
    await supabase.from('usuarios').update({'status': novoStatus}).eq('id', id);
    await _carregarUsuarios();
  }

  void _mostrarFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
              const Text('Novo Usuário',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                    labelText: 'Nome completo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Senha', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _perfilSelecionado,
                decoration: const InputDecoration(
                    labelText: 'Perfil', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'fiscal', child: Text('Fiscal')),
                  DropdownMenuItem(
                      value: 'motorista', child: Text('Motorista')),
                  DropdownMenuItem(value: 'monitor', child: Text('Monitor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _perfilSelecionado = v!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Criar Usuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _corPerfil(String perfil) {
    switch (perfil) {
      case 'admin':
        return Colors.red;
      case 'fiscal':
        return const Color(0xFF1E6B3C);
      case 'motorista':
        return Colors.blue;
      case 'monitor':
        return Colors.purple;
      case 'estudante':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filtro por perfil
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                for (final f in [
                  'todos',
                  'admin',
                  'estudante',
                  'fiscal',
                  'motorista',
                  'monitor'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f[0].toUpperCase() + f.substring(1)),
                      selected: _filtro == f,
                      onSelected: (_) {
                        setState(() {
                          _filtro = f;
                          _carregando = true;
                        });
                        _carregarUsuarios();
                      },
                      selectedColor: const Color(0xFF1E6B3C).withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _usuarios.length,
                    itemBuilder: (context, i) {
                      final u = _usuarios[i];
                      final ativo = u['status'] == 'ativo';
                      final cor = _corPerfil(u['perfil']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ativo ? cor : Colors.grey,
                          child: Text(
                            u['nome_completo'][0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u['nome_completo'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${u['perfil'].toString().toUpperCase()} • ${u['email']}'),
                        trailing: Switch(
                          value: ativo,
                          activeColor: const Color(0xFF1E6B3C),
                          onChanged: u['perfil'] == 'admin'
                              ? null
                              : (_) => _alterarStatus(u['id'], u['status']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
