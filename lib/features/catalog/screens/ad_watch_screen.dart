import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Simulation d'une publicité vidéo (pas de vrai SDK publicitaire branché
/// pour l'instant — voir le commentaire de `POST /ad-unlock` côté serveur :
/// "validation minimale pour la démo"). Décompte de 5 secondes, impossible à
/// passer plus vite, puis renvoie la durée réellement "regardée" en
/// millisecondes à l'appelant (`Navigator.pop`) pour que ce soit CETTE
/// valeur, jamais une valeur inventée, qui soit envoyée au serveur.
class AdWatchScreen extends StatefulWidget {
  const AdWatchScreen({super.key});

  static const int _totalSeconds = 5;

  @override
  State<AdWatchScreen> createState() => _AdWatchScreenState();
}

class _AdWatchScreenState extends State<AdWatchScreen> {
  int _remaining = AdWatchScreen._totalSeconds;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _remaining <= 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1B2C),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ondemand_video_outlined, color: Colors.white70, size: 56),
                  const SizedBox(height: 20),
                  const Text(
                    'Publicité en cours...',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1 - (_remaining / AdWatchScreen._totalSeconds),
                          strokeWidth: 4,
                          color: AppTheme.brandGreen,
                          backgroundColor: Colors.white24,
                        ),
                        Text(
                          done ? '' : '$_remaining',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: done
                        ? () => Navigator.of(context).pop(_stopwatch.elapsedMilliseconds)
                        : null,
                    child: Text(done ? 'Continuer' : 'Patientez...'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
