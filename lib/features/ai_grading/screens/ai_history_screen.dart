import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../models/ai_submission.dart';
import '../services/ai_grading_service.dart';

/// Historique complet des corrections IA de l'élève connecté
/// (`GET /api/ai/history`), plus récent en premier.
class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  late final AiGradingService _service;
  late Future<List<AiSubmission>> _future;

  @override
  void initState() {
    super.initState();
    _service = AiGradingService(apiClient: context.read<AuthState>().apiClient);
    _future = _service.fetchHistory();
  }

  Color _noteColor(num? note) {
    if (note == null) return Colors.black54;
    if (note >= 14) return AppTheme.brandGreen;
    if (note >= 10) return Colors.orange;
    return Colors.red;
  }

  String _dateLabel(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes corrections IA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: FutureBuilder<List<AiSubmission>>(
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
                        "Impossible de charger l'historique.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _future = _service.fetchHistory()),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final submissions = snapshot.data ?? [];
            if (submissions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Vous n'avez encore envoyé aucune copie pour correction IA.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final next = _service.fetchHistory();
                setState(() => _future = next);
                await next.catchError((_) => <AiSubmission>[]);
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final s = submissions[index];
                  final color = _noteColor(s.note);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(
                        s.documentTitle ?? 'Document',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(_dateLabel(s.createdAt), style: const TextStyle(fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.noteLabel,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.feedback != null && s.feedback!.isNotEmpty) ...[
                                Text(s.feedback!, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                                const SizedBox(height: 12),
                              ],
                              if (s.strengths.isNotEmpty) ...[
                                const Text('Points forts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 4),
                                ...s.strengths.map((t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text('• $t', style: const TextStyle(fontSize: 12.5)),
                                    )),
                                const SizedBox(height: 10),
                              ],
                              if (s.weaknesses.isNotEmpty) ...[
                                const Text('Points à travailler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 4),
                                ...s.weaknesses.map((t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text('• $t', style: const TextStyle(fontSize: 12.5)),
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ],
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
