import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ma_app/pages/chat/chat_page.dart';

final supabase = Supabase.instance.client;

class ListaContatos extends StatefulWidget {
  final Map<String, dynamic> usuarioAtual;

  const ListaContatos({super.key, required this.usuarioAtual});

  @override
  State<ListaContatos> createState() => _ListaContatosState();
}

class _ListaContatosState extends State<ListaContatos> {
  List<Map<String, dynamic>> _contatos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarContatos();
  }

  Future<void> _carregarContatos() async {
    try {
      final perfil = widget.usuarioAtual['perfil'] as String;
      print('PERFIL ATUAL: $perfil');

      List<Map<String, dynamic>> contatos;

      if (perfil == 'estudante') {
        contatos = await supabase
            .from('usuarios')
            .select('id, nome_completo, perfil, status')
            .inFilter('perfil', ['fiscal', 'monitor', 'motorista', 'admin']).eq(
                'status', 'ativo');
      } else {
        contatos = await supabase
            .from('usuarios')
            .select('id, nome_completo, perfil, status')
            .neq('id', widget.usuarioAtual['id'])
            .eq('status', 'ativo');
      }

      setState(() {
        _contatos = List<Map<String, dynamic>>.from(contatos);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
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
        title: const Text('Mensagens'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _contatos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum contato disponível.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _contatos.length,
                  itemBuilder: (context, i) {
                    final contato = _contatos[i];
                    final cor = _corPerfil(contato['perfil']);

                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            destinatario: contato,
                            usuarioAtual: widget.usuarioAtual,
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: cor,
                        child: Text(
                          contato['nome_completo'][0],
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        contato['nome_completo'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        contato['perfil'].toString().toUpperCase(),
                        style: TextStyle(color: cor, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
    );
  }
}
