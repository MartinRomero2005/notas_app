import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../services/api_service.dart';
import '../widgets/nota_card.dart';
import 'editar_nota_screen.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final ApiService api = ApiService.instance;
  final TextEditingController busquedaController = TextEditingController();
  List<Nota> notas = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarNotas();
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  Future<void> cargarNotas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final resultado = await api.obtenerNotas();
      if (mounted) {
        setState(() {
          notas = resultado;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'No se pudieron cargar las calificaciones.';
          cargando = false;
        });
      }
    }
  }

  Future<void> agregarNota() async {
    final resultado = await Navigator.push<Nota>(
      context,
      MaterialPageRoute(builder: (context) => const EditarNotaScreen()),
    );

    if (resultado != null) {
      await api.crearNota(resultado);
      await cargarNotas();
      mostrarMensaje('Calificación creada y pendiente de sincronización.');
    }
  }

  Future<void> editarNota(Nota nota) async {
    final resultado = await Navigator.push<Nota>(
      context,
      MaterialPageRoute(builder: (context) => EditarNotaScreen(nota: nota)),
    );

    if (resultado != null) {
      await api.actualizarNota(resultado);
      await cargarNotas();
      mostrarMensaje('Calificación modificada y pendiente de sincronización.');
    }
  }

  Future<void> eliminarNota(Nota nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar calificación'),
        content: Text('¿Eliminar la calificación de ${nota.estudiante}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || nota.id == null) {
      return;
    }

    await api.eliminarNota(nota.id!);
    await cargarNotas();
    mostrarMensaje('Calificación eliminada.');
  }

  Future<void> sincronizar() async {
    final cantidad = await api.sincronizarConLaNube();
    await cargarNotas();
    mostrarMensaje(
      cantidad == 0
          ? 'La información ya estaba sincronizada.'
          : '$cantidad calificación(es) sincronizada(s) con la nube.',
    );
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final textoBusqueda = busquedaController.text.trim().toLowerCase();
    final notasFiltradas = notas.where((nota) {
      return nota.estudiante.toLowerCase().contains(textoBusqueda) ||
          nota.asignatura.toLowerCase().contains(textoBusqueda);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de calificaciones'),
        actions: [
          IconButton(
            onPressed: sincronizar,
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Sincronizar con la nube',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: cargarNotas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: busquedaController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Buscar estudiante o asignatura',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: textoBusqueda.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                busquedaController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: notasFiltradas.isEmpty
                      ? Center(
                          child: Text(
                            notas.isEmpty
                                ? 'No hay calificaciones registradas.'
                                : 'No hay resultados para la búsqueda.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notasFiltradas.length,
                          itemBuilder: (context, index) {
                            final nota = notasFiltradas[index];
                            return NotaCard(
                              nota: nota,
                              onEdit: () => editarNota(nota),
                              onDelete: () => eliminarNota(nota),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: agregarNota,
        icon: const Icon(Icons.add),
        label: const Text('Agregar nota'),
      ),
    );
  }
}
