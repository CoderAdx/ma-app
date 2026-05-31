import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ViagemService {
  static Future<Map<String, dynamic>?> getViagemHoje() async {
    try {
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final viagem = await supabase
          .from('viagens')
          .select(
              'id, status, horario_limite_confirmacao, horario_partida_volta, veiculos(placa, modelo, capacidade_assentos)')
          .eq('data_viagem', hoje)
          .eq('status', 'aberta')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return viagem;
    } catch (e) {
      return null;
    }
  }
}
