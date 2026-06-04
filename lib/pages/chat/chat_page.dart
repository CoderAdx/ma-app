import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

final supabase = Supabase.instance.client;

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> destinatario;
  final Map<String, dynamic> usuarioAtual;

  const ChatPage({
    super.key,
    required this.destinatario,
    required this.usuarioAtual,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _mensagens = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  RealtimeChannel? _canal;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _carregarMensagens();
    _escutarMensagens();
  }

  @override
  void dispose() {
    _canal?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarMensagens() async {
    try {
      final minhaId = widget.usuarioAtual['id'];
      final destinatarioId = widget.destinatario['id'];

      final mensagens = await supabase
          .from('mensagens')
          .select('id, conteudo, enviado_em, remetente_id, destinatario_id')
          .or('and(remetente_id.eq.$minhaId,destinatario_id.eq.$destinatarioId),'
              'and(remetente_id.eq.$destinatarioId,destinatario_id.eq.$minhaId)')
          .order('enviado_em', ascending: true);

      setState(() {
        _mensagens = List<Map<String, dynamic>>.from(mensagens);
        _carregando = false;
      });

      _scrollParaBaixo();
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _escutarMensagens() {
    final minhaId = widget.usuarioAtual['id'];
    final destinatarioId = widget.destinatario['id'];

    _canal = supabase
        .channel('chat_${minhaId}_$destinatarioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensagens',
          callback: (payload) {
            final nova = payload.newRecord;
            final remetenteId = nova['remetente_id'];
            final destId = nova['destinatario_id'];

            // Só adiciona se for desta conversa
            if ((remetenteId == minhaId && destId == destinatarioId) ||
                (remetenteId == destinatarioId && destId == minhaId)) {
              setState(() => _mensagens.add(nova));
              _scrollParaBaixo();
            }
          },
        )
        .subscribe();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    _controller.clear();

    try {
      await supabase.from('mensagens').insert({
        'remetente_id': widget.usuarioAtual['id'],
        'destinatario_id': widget.destinatario['id'],
        'conteudo': texto,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollParaBaixo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minhaId = widget.usuarioAtual['id'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: widget.destinatario['foto_url'] != null
                  ? NetworkImage(widget.destinatario['foto_url'] as String)
                  : null,
              child: widget.destinatario['foto_url'] == null
                  ? Text(
                      widget.destinatario['nome_completo'][0],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinatario['nome_completo'],
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  widget.destinatario['perfil'].toString().toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lista de mensagens
                Expanded(
                  child: _mensagens.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma mensagem ainda.\nInicie a conversa!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _mensagens.length,
                          itemBuilder: (context, i) {
                            final msg = _mensagens[i];
                            final ehMinha = msg['remetente_id'] == minhaId;
                            final hora =
                                DateTime.parse(msg['enviado_em'] as String);

                            return Align(
                              alignment: ehMinha
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: ehMinha
                                      ? const Color(0xFF1E6B3C)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(ehMinha ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(ehMinha ? 4 : 16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg['conteudo'],
                                      style: TextStyle(
                                        color: ehMinha
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeago.format(hora, locale: 'pt_BR'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ehMinha
                                            ? Colors.white60
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Campo de texto
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _enviar(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1E6B3C),
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                          onPressed: _enviar,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
