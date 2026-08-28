import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../models/document_item.dart';
import '../models/purchase.dart';
import '../services/payment_service.dart';
import 'ad_watch_screen.dart';
import 'payment_pending_screen.dart';

/// Choix du moyen de débloquer un document payant : publicité gratuite (si
/// autorisée par le document) ou paiement Bankily/Masrivi/Sedad.
///
/// Renvoie `true` via `Navigator.pop` si le document a été débloqué avant de
/// quitter cet écran (déblocage pub immédiat, ou retour depuis l'écran de
/// paiement une fois confirmé) — la fiche document doit alors se
/// rafraîchir.
class UnlockScreen extends StatefulWidget {
  final DocumentItem document;

  const UnlockScreen({super.key, required this.document});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  late final PaymentService _paymentService;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _paymentService = PaymentService(apiClient: apiClient);
  }

  Future<void> _watchAd() async {
    final watchedMs = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const AdWatchScreen(), fullscreenDialog: true),
    );
    if (watchedMs == null || !mounted) return; // annulé

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final unlocked = await _paymentService.adUnlock(
        documentId: widget.document.id,
        watchedMs: watchedMs,
      );
      if (!mounted) return;
      if (unlocked) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _busy = false;
          _error = "Le déblocage n'a pas pu être confirmé. Réessayez.";
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      });
    }
  }

  Future<void> _payWith(String method) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final purchase = await _paymentService.initiate(
        documentId: widget.document.id,
        method: method,
      );
      if (!mounted) return;
      setState(() => _busy = false);

      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentPendingScreen(
            purchase: purchase,
            documentTitle: widget.document.title,
          ),
        ),
      );
      if (!mounted) return;
      if (unlocked == true) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Débloquer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doc.matiere} · Série ${doc.serie} · ${doc.annee}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                if (doc.adUnlock) ...[
                  _OptionCard(
                    icon: Icons.ondemand_video_outlined,
                    iconColor: AppTheme.brandGreen,
                    title: 'Regarder une publicité',
                    subtitle: 'Débloquez ce document gratuitement.',
                    onTap: _busy ? null : _watchAd,
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('ou payer', style: TextStyle(color: Colors.black45, fontSize: 12.5)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  '${doc.priceLabel} — choisissez un moyen de paiement',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...kPaymentMethods.map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: AppTheme.brandBlue,
                      title: paymentMethodLabel(method),
                      subtitle: 'Payer ${doc.priceLabel} via ${paymentMethodLabel(method)}',
                      onTap: _busy ? null : () => _payWith(method),
                    ),
                  ),
                ),

                if (_busy) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF6F8FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
