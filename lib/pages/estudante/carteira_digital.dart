import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class CarteiraDigital extends StatefulWidget {
  const CarteiraDigital({super.key});

  @override
  State<CarteiraDigital> createState() => _CarteiraDigitalState();
}

class _CarteiraDigitalState extends State<CarteiraDigital> {
  Map<String, dynamic>? _usuario;
  Map<String, dynamic>? _estudante;
  bool _carregando = true;
  bool _mostrandoVerso = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUsuario = prefs.getString('carteira_usuario');
    final cachedEstudante = prefs.getString('carteira_estudante');

    print('Cache usuario: $cachedUsuario');
    print('Cache estudante: $cachedEstudante');

    // Tenta atualizar do banco primeiro (se tiver internet)
    try {
      final usuario = await AuthService.getUsuarioAtual()
          .timeout(const Duration(seconds: 5));
      final estudante = await AuthService.getPerfilEstudante()
          .timeout(const Duration(seconds: 5));

      if (usuario != null && estudante != null) {
        // Salva no cache
        await prefs.setString('carteira_usuario', jsonEncode(usuario));
        await prefs.setString('carteira_estudante', jsonEncode(estudante));

        if (mounted) {
          setState(() {
            _usuario = usuario;
            _estudante = estudante;
            _carregando = false;
          });
        }
        return;
      }
    } catch (e) {
      // Sem internet — cai para o cache abaixo
    }

    // Sem internet ou erro — carrega do cache
    if (cachedUsuario != null && cachedEstudante != null) {
      if (mounted) {
        setState(() {
          _usuario = jsonDecode(cachedUsuario);
          _estudante = jsonDecode(cachedEstudante);
          _carregando = false;
        });
      }
    } else {
      // Sem internet E sem cache — primeira vez offline
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_usuario == null || _estudante == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carteira Digital')),
        body: const Center(
          child: Text('Erro ao carregar carteira. Verifique sua conexão.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Carteira Digital'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            // Toque na carteira vira para ver o verso
            onTap: () => setState(() => _mostrandoVerso = !_mostrandoVerso),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _mostrandoVerso ? _buildVerso() : _buildFrente(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrente() {
    final estudante = _estudante!;
    final instituicao = estudante['instituicoes'] as Map<String, dynamic>?;

    return _buildCard(
      key: const ValueKey('frente'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho verde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E6B3C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MARUIM ACADÊMICO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Transporte Universitário Municipal',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do estudante
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF1E6B3C), width: 2),
                  ),
                  child: estudante['foto_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            estudante['foto_url'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 48, color: Colors.grey),
                ),
                const SizedBox(width: 16),

                // Dados do estudante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _usuario!['nome_completo'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfo('CPF', _usuario!['cpf'] ?? 'Não informado'),
                      _buildInfo('Instituição',
                          instituicao?['nome'] ?? 'Não informado'),
                      _buildInfo('Curso', estudante['curso']),
                      _buildInfo('Turno',
                          (estudante['turno'] as String).toUpperCase()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rodapé com validade
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Válido até: ${estudante['validade_carteira']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Text(
                  'Toque para ver o verso',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerso() {
    return _buildCard(
      key: const ValueKey('verso'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E6B3C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'TERMOS DE USO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O portador desta carteira compromete-se a:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _buildTermo(
                    'Cancelar a reserva com antecedência mínima de 2 horas caso não possa comparecer.'),
                _buildTermo(
                    'Manter conduta respeitosa com colegas e operadores.'),
                _buildTermo(
                    'Apresentar esta carteira quando solicitado pelo fiscal ou motorista.'),
                _buildTermo(
                    'O acúmulo de 100 pontos em penalidades resulta em suspensão de 3 dias.'),
                const SizedBox(height: 16),

                // Carimbo digital
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF1E6B3C), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified,
                          color: Color(0xFF1E6B3C), size: 32),
                      const SizedBox(height: 4),
                      const Text(
                        'SECRETARIA DE TRANSPORTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Color(0xFF1E6B3C),
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'Prefeitura Municipal de Maruim/SE',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contrato assinado em: ${_estudante!['contrato_assinado_em']?.toString().substring(0, 10) ?? 'N/A'}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Widget _buildTermo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: Color(0xFF1E6B3C), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
