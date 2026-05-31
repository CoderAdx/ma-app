import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RealtimeService {
  static RealtimeChannel? _canal;

  /// Inicia a escuta de alertas da viagem atual.
  /// Chama [onAlerta] sempre que um novo alerta for inserido.
  static void escutarAlertas({
    required String viagemId,
    required void Function(Map<String, dynamic> payload) onAlerta,
  }) {
    // Cancela canal anterior se existir
    pararEscuta();

    _canal = supabase
        .channel('alertas_viagem_$viagemId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alertas_viagem',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'viagem_id',
            value: viagemId,
          ),
          callback: (payload) {
            onAlerta(payload.newRecord);
          },
        )
        .subscribe();
  }

  static void pararEscuta() {
    _canal?.unsubscribe();
    _canal = null;
  }
}
