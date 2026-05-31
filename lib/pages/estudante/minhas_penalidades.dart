import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ma_app/services/auth_service.dart';

final supabase = Supabase.instance.client;

class MinhasPenalidades extends StatefulWidget {
  const MinhasPenalidades({super.key});

  @override
  State<MinhasPenalidades> createState() => _MinhasPenalidadesState();
}

class _MinhasPenalidadesState extends State<MinhasPenalidades> {
  List<Map<String, dynamic>> _penalidades = [];
  int _pontos = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final estudante = await AuthService.getPerfilEstudante();
      if (estudante == null) return;

      final penalidades = await supabase
          .from('penalidades')
          .select('id, descricao, pontos, status, criado_em')
          .eq('estudante_id', estudante['id'])
          .order('criado_em', ascending: false);

      setState(() {
        _penalidades = List<Map<String, dynamic>>.from(penalidades);
        _pontos = estudante['pontos_penalidade'] as int;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Color _corPontos() {
    if (_pontos >= 100) return Colors.red;
    if (_pontos >= 80) return Colors.orange;
    if (_pontos >= 50) return Colors.yellow[700]!;
    return const Color(0xFF1E6B3C);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Penalidades'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
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
                    // Card de pontos
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _corPontos(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Pontos Acumulados',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_pontos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'de 100 pontos',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Barra de progresso
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (_pontos / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_pontos < 100)
                            Text(
                              'Faltam ${100 - _pontos} pontos para suspensão',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            )
                          else
                            const Text(
                              'Conta suspensa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Histórico
                    Text(
                      'Histórico (${_penalidades.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_penalidades.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text(
                                'Nenhuma penalidade registrada.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._penalidades.map((p) => _buildCard(p)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final status = p['status'] as String;
    final pontos = p['pontos'] as int;
    final data = (p['criado_em'] as String).substring(0, 10);

    Color corStatus;
    IconData iconeStatus;
    String labelStatus;

    switch (status) {
      case 'aprovada':
        corStatus = Colors.red;
        iconeStatus = Icons.gavel;
        labelStatus = 'Aplicada';
        break;
      case 'pendente':
        corStatus = Colors.orange;
        iconeStatus = Icons.hourglass_empty;
        labelStatus = 'Pendente';
        break;
      case 'cancelada':
        corStatus = Colors.grey;
        iconeStatus = Icons.cancel_outlined;
        labelStatus = 'Cancelada';
        break;
      default:
        corStatus = Colors.grey;
        iconeStatus = Icons.info_outline;
        labelStatus = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corStatus.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconeStatus, color: corStatus, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['descricao'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      data,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: corStatus.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        labelStatus,
                        style: TextStyle(
                            fontSize: 11,
                            color: corStatus,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$pontos pts',
              style: TextStyle(
                color: corStatus,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
