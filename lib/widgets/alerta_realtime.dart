import 'package:flutter/material.dart';
import 'package:ma_app/services/realtime_service.dart';

class AlertaRealtimeWrapper extends StatefulWidget {
  final String viagemId;
  final Widget child;

  const AlertaRealtimeWrapper({
    super.key,
    required this.viagemId,
    required this.child,
  });

  @override
  State<AlertaRealtimeWrapper> createState() => _AlertaRealtimeWrapperState();
}

class _AlertaRealtimeWrapperState extends State<AlertaRealtimeWrapper> {
  @override
  void initState() {
    super.initState();
    _iniciarEscuta();
  }

  void _iniciarEscuta() {
    RealtimeService.escutarAlertas(
      viagemId: widget.viagemId,
      onAlerta: (payload) {
        final tipo = payload['tipo'] as String? ?? '';
        final payloadData = payload['payload'] as Map<String, dynamic>? ?? {};

        if (tipo == 'faltantes') {
          _mostrarPopupFaltantes(payloadData);
        } else if (tipo.startsWith('proximidade_')) {
          _mostrarPopupProximidade(payloadData);
        }
      },
    );
  }

  void _mostrarPopupFaltantes(Map<String, dynamic> payload) {
    final nomes = List<String>.from(payload['nomes'] ?? []);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.red.withOpacity(0.5),
      builder: (_) => _PopupVermelho(nomes: nomes),
    );
  }

  void _mostrarPopupProximidade(Map<String, dynamic> payload) {
    final instituicao = payload['instituicao'] as String? ?? '';
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E6B3C), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.directions_bus, color: Color(0xFF1E6B3C)),
            SizedBox(width: 8),
            Text('Ônibus se aproximando!'),
          ],
        ),
        content: Text(
          'O transporte está chegando em $instituicao. Prepare-se para embarcar!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6B3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    RealtimeService.pararEscuta();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Pop-up vermelho piscante
class _PopupVermelho extends StatefulWidget {
  final List<String> nomes;
  const _PopupVermelho({required this.nomes});

  @override
  State<_PopupVermelho> createState() => _PopupVermelhoState();
}

class _PopupVermelhoState extends State<_PopupVermelho>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Dialog(
          backgroundColor:
              Colors.red.withOpacity(0.9 + (_animation.value * 0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 56 + (_animation.value * 8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ATENÇÃO — FALTANTES!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...widget.nomes.map((nome) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person_off,
                              color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Text(
                  'Não parta antes de localizar esses passageiros!',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
