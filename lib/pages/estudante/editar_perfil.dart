import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

final supabase = Supabase.instance.client;

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  bool _salvando = false;
  String? _fotoAtualUrl;

  @override
  void initState() {
    super.initState();
    _carregarFotoAtual();
  }

  Future<void> _carregarFotoAtual() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final estudante = await supabase
        .from('estudantes')
        .select('foto_url')
        .eq('usuario_id', userId)
        .single();

    setState(() => _fotoAtualUrl = estudante['foto_url']);
  }

  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );

    if (imagem == null) return;

    setState(() => _salvando = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Sessão expirada');

      final arquivo = File(imagem.path);
      final bytes = await arquivo.readAsBytes();
      final extensao = imagem.path.split('.').last.toLowerCase();
      final caminho = '$userId/foto.$extensao';

      // Upload para o Supabase Storage
      await supabase.storage.from('fotos-perfil').uploadBinary(
            caminho,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extensao',
              upsert: true, // substitui se já existir
            ),
          );

      // Pega a URL pública
      final url = supabase.storage.from('fotos-perfil').getPublicUrl(caminho);

      // Atualiza o perfil do estudante
      await supabase
          .from('estudantes')
          .update({'foto_url': url}).eq('usuario_id', userId);

      setState(() => _fotoAtualUrl = url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao enviar foto: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );

    if (imagem == null) return;

    setState(() => _salvando = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Sessão expirada');

      final arquivo = File(imagem.path);
      final bytes = await arquivo.readAsBytes();
      final caminho = '$userId/foto.jpg';

      await supabase.storage.from('fotos-perfil').uploadBinary(
            caminho,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final url = supabase.storage.from('fotos-perfil').getPublicUrl(caminho);

      await supabase
          .from('estudantes')
          .update({'foto_url': url}).eq('usuario_id', userId);

      setState(() => _fotoAtualUrl = url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao enviar foto: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto atual
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _fotoAtualUrl != null
                        ? NetworkImage(_fotoAtualUrl!)
                        : null,
                    child: _fotoAtualUrl == null
                        ? const Icon(Icons.person, size: 80, color: Colors.grey)
                        : null,
                  ),
                  if (_salvando)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Escolha como adicionar sua foto:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _salvando ? null : _selecionarFoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Escolher da galeria'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1E6B3C),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _salvando ? null : _tirarFoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Tirar foto'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
