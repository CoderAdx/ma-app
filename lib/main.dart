import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:ma_app/config.dart';
import 'package:ma_app/pages/home_router.dart';
import 'package:ma_app/pages/login_page.dart';
import 'package:ma_app/pages/redefinir_senha.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MaApp());
}

class MaApp extends StatelessWidget {
  const MaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maruim Acadêmico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6B3C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _redefinindoSenha = false;

  @override
  void initState() {
    super.initState();
    _escutarDeepLinks();
  }

  void _escutarDeepLinks() {
    final appLinks = AppLinks();

    // Link recebido com app fechado
    appLinks.getInitialLink().then((uri) {
      if (uri != null && uri.toString().contains('reset-password')) {
        setState(() => _redefinindoSenha = true);
      }
    });

    // Link recebido com app aberto
    appLinks.uriLinkStream.listen((uri) {
      if (uri.toString().contains('reset-password')) {
        setState(() => _redefinindoSenha = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_redefinindoSenha) {
      return RedefinirSenha();
    }

    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        if (session != null) {
          return const HomeRouter();
        }

        return const LoginPage();
      },
    );
  }
}
