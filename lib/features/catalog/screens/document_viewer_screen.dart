import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../auth/state/auth_state.dart';

/// Visionneuse sécurisée : appelle `GET /api/documents/:id/view-pages`, qui
/// renvoie chaque page du document déjà filigranée (nom + numéro du
/// lecteur) sous forme d'image JPEG — jamais le fichier PDF original. Pas de
/// bouton "télécharger"/"imprimer" possible ici (contrairement à un PDF
/// affiché tel quel), volontairement, comme documenté côté serveur.
class DocumentViewerScreen extends StatefulWidget {
  final String documentId;
  final String title;

  const DocumentViewerScreen({super.key, required this.documentId, required this.title});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late final ApiClient _apiClient;
  late Future<List<Uint8List>> _future;
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _apiClient = context.read<AuthState>().apiClient;
    _future = _loadPages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Uint8List>> _loadPages() async {
    final data = await _apiClient.get('/documents/${widget.documentId}/view-pages');
    final pages = (data['pages'] as List<dynamic>? ?? const []);
    return pages.map((p) {
      final dataUri = p as String;
      final commaIndex = dataUri.indexOf(',');
      final base64Part = commaIndex >= 0 ? dataUri.substring(commaIndex + 1) : dataUri;
      return base64Decode(base64Part);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Uint8List>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Colors.white70));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "Impossible d'ouvrir ce document pour le moment.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _future = _loadPages()),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final pages = snapshot.data!;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF16283F),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Document sécurisé — votre nom et numéro apparaissent en filigrane sur chaque page.',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.memory(pages[index], fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFF16283F),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Page ${_currentPage + 1} / ${pages.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
