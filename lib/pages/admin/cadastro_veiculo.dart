import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CadastroVeiculo extends StatefulWidget {
  const CadastroVeiculo({super.key});

  @override
  State<CadastroVeiculo> createState() => _CadastroVeiculoState();
}

class _CadastroVeiculoState extends State<CadastroVeiculo> {
  List<Map<String, dynamic>> _veiculos = [];
  bool _carregando = true;

  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _capacidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  Future<void> _carregarVeiculos() async {
    final veiculos = await supabase.from('veiculos').select().order('placa');
    setState(() {
      _veiculos = List<Map<String, dynamic>>.from(veiculos);
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    if (_placaController.text.isEmpty ||
        _modeloController.text.isEmpty ||
        _capacidadeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha todos os campos.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await supabase.from('veiculos').insert({
        'placa': _placaController.text.trim().toUpperCase(),
        'modelo': _modeloController.text.trim(),
        'capacidade_assentos': int.parse(_capacidadeController.text),
        'status': 'ativo',
      });

      _placaController.clear();
      _modeloController.clear();
      _capacidadeController.clear();

      await _carregarVeiculos();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veículo cadastrado!'),
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

  Future<void> _alterarStatus(String id, String statusAtual) async {
    final novoStatus = statusAtual == 'ativo' ? 'inativo' : 'ativo';
    await supabase.from('veiculos').update({'status': novoStatus}).eq('id', id);
    await _carregarVeiculos();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Novo Veículo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _placaController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Placa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modeloController,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capacidadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacidade de assentos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1E6B3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículos'),
        backgroundColor: const Color(0xFF1E6B3C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        backgroundColor: const Color(0xFF1E6B3C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _veiculos.isEmpty
              ? const Center(
                  child: Text('Nenhum veículo cadastrado.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _veiculos.length,
                  itemBuilder: (context, i) {
                    final v = _veiculos[i];
                    final ativo = v['status'] == 'ativo';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            ativo ? const Color(0xFF1E6B3C) : Colors.grey,
                        child: const Icon(Icons.directions_bus,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(v['placa'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${v['modelo']} • ${v['capacidade_assentos']} assentos'),
                      trailing: Switch(
                        value: ativo,
                        activeColor: const Color(0xFF1E6B3C),
                        onChanged: (_) => _alterarStatus(v['id'], v['status']),
                      ),
                    );
                  },
                ),
    );
  }
}
