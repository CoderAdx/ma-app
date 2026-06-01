import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CadastroInstituicao extends StatefulWidget {
  const CadastroInstituicao({super.key});

  @override
  State<CadastroInstituicao> createState() => _CadastroInstituicaoState();
}

class _CadastroInstituicaoState extends State<CadastroInstituicao> {
  List<Map<String, dynamic>> _instituicoes = [];
  bool _carregando = true;

  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarInstituicoes();
  }

  Future<void> _carregarInstituicoes() async {
    final inst = await supabase.from('instituicoes').select().order('nome');
    setState(() {
      _instituicoes = List<Map<String, dynamic>>.from(inst);
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    if (_nomeController.text.isEmpty ||
        _cidadeController.text.isEmpty ||
        _latController.text.isEmpty ||
        _lonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha nome, cidade e coordenadas.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await supabase.from('instituicoes').insert({
        'nome': _nomeController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'latitude': double.parse(_latController.text.trim()),
        'longitude': double.parse(_lonController.text.trim()),
      });

      _nomeController.clear();
      _enderecoController.clear();
      _cidadeController.clear();
      _latController.clear();
      _lonController.clear();

      await _carregarInstituicoes();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Instituição cadastrada!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nova Instituição',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                    labelText: 'Nome da instituição',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                    labelText: 'Endereço', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cidadeController,
                decoration: const InputDecoration(
                    labelText: 'Cidade', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text(
                'Coordenadas GPS (encontre no Google Maps)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: const InputDecoration(
                          labelText: 'Latitude', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lonController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: const InputDecoration(
                          labelText: 'Longitude', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instituições'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _instituicoes.isEmpty
              ? const Center(
                  child: Text('Nenhuma instituição cadastrada.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _instituicoes.length,
                  itemBuilder: (context, i) {
                    final inst = _instituicoes[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.account_balance,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(inst['nome'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${inst['cidade']} • ${inst['latitude']}, ${inst['longitude']}'),
                    );
                  },
                ),
    );
  }
}
