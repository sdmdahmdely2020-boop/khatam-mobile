import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../models/favorite_document.dart';
import '../services/favorites_service.dart';
import 'document_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesService _service;
  late Future<List<FavoriteDocument>> _future;

  @override
  void initState() {
    super.initState();
    _service = FavoritesService(apiClient: context.read<AuthState>().apiClient);
    _future = _service.fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: FutureBuilder<List<FavoriteDocument>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger vos favoris.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _future = _service.fetchFavorites()),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final favorites = snapshot.data ?? [];
            if (favorites.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Aucun favori pour l'instant. Ouvrez un document et appuyez sur le cœur pour l'ajouter ici.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final next = _service.fetchFavorites();
                setState(() => _future = next);
                // Erreur ignorée ici volontairement : le FutureBuilder ci-dessus
                // affiche déjà l'état d'erreur à partir de ce même _future.
                await next.catchError((_) => <FavoriteDocument>[]);
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final doc = favorites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailScreen(documentId: doc.id),
                          ),
                        );
                        if (mounted) setState(() => _future = _service.fetchFavorites());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 74,
                                child: doc.previewUrl.isEmpty
                                    ? Container(color: const Color(0xFFEFF3F8))
                                    : Image.network(
                                        doc.previewUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: const Color(0xFFEFF3F8)),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${doc.matiere} · Série ${doc.serie} · ${doc.annee}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    doc.priceLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                      color: doc.free ? AppTheme.brandGreen : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
