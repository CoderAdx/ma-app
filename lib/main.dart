import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ma_app/config.dart';

// Acesso global ao cliente Supabase
// Em qualquer arquivo do projeto você usa: supabase.from('tabela')
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase com suas credenciais
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
          seedColor: const Color(0xFF1E6B3C), // Verde prefeitura
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Decide qual tela mostrar baseado no estado do login
      home: const AuthGate(),
    );
  }
}

// AuthGate — portão de entrada do app
// Verifica se o usuário está logado e redireciona para a tela certa
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Supabase emite um evento toda vez que o estado de auth muda
      // (login, logout, token expirado)
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // Se tem sessão ativa → vai para o app
        // Se não tem → vai para o login
        if (session != null) {
          return const HomeTemp();
        }

        return const LoginPage();
      },
    );
  }
}

// Tela temporária — substituiremos pelo roteador de perfis depois
class HomeTemp extends StatelessWidget {
  const HomeTemp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MA – Maruim Acadêmico')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Logado com sucesso!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await supabase.auth.signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela de Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro = null;

  Future<void> _login() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      // O AuthGate detecta a mudança de sessão automaticamente
      // e redireciona para HomeTemp sem precisar de Navigator
    } on AuthException catch (e) {
      setState(() => _erro = 'Email ou senha incorretos');
    } catch (e) {
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / título
              Icon(Icons.directions_bus_rounded, size: 72, color: cor.primary),
              const SizedBox(height: 16),
              Text(
                'Maruim Acadêmico',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: cor.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transporte Universitário',
                textAlign: TextAlign.center,
                style: TextStyle(color: cor.outline),
              ),
              const SizedBox(height: 48),

              // Campo email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo senha
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),

              // Mensagem de erro
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_erro!,
                      style: TextStyle(color: cor.error),
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 16),

              // Botão login
              ElevatedButton(
                onPressed: _carregando ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: cor.primary,
                  foregroundColor: cor.onPrimary,
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
