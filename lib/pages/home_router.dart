import 'package:flutter/material.dart';
import 'package:ma_app/services/auth_service.dart';
import 'package:ma_app/pages/estudante/estudante_home.dart';
import 'package:ma_app/pages/fiscal/fiscal_home.dart';
import 'package:ma_app/pages/operador/operador_home.dart';
import 'package:ma_app/pages/admin/admin_home.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  Map<String, dynamic>? _usuario;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final usuario = await AuthService.getUsuarioAtual();
    setState(() {
      _usuario = usuario;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Erro ao carregar perfil')),
      );
    }

    // Redireciona baseado no perfil
    switch (_usuario!['perfil']) {
      case 'estudante':
        return EstudanteHome(usuario: _usuario!);
      case 'fiscal':
        return FiscalHome(usuario: _usuario!);
      case 'admin':
        return AdminHome(usuario: _usuario!);
      case 'motorista':
      case 'monitor':
        return OperadorHome(usuario: _usuario!);
      default:
        return const Scaffold(
          body: Center(child: Text('Perfil não reconhecido')),
        );
    }
  }
}
