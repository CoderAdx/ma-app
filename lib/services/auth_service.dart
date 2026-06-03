import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthService {
  // Busca os dados do usuário logado na tabela public.usuarios
  static Future<Map<String, dynamic>?> getUsuarioAtual() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('usuarios')
          .select('id, nome_completo, perfil, status, cpf') // <- adiciona cpf
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Busca dados extras do estudante (pontos, curso, instituição)
  static Future<Map<String, dynamic>?> getPerfilEstudante() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase.from('estudantes').select('''
            id, curso, turno, pontos_penalidade,
            validade_carteira, foto_url,
            contrato_assinado_em,
            instituicoes(nome, cidade)
          ''').eq('usuario_id', userId).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
