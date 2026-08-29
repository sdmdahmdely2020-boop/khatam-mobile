import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/models/purchase.dart' show paymentMethodLabel;
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';

enum _Step { reference, waiting, confirmed, failed }

/// Version "abonnement" de `catalog/screens/payment_pending_screen.dart` —
/// même logique exacte (numéro de reçu → attente → confirmation manuelle
/// admin), dupliquée plutôt que partagée pour ne jamais risquer de casser le
/// flux d'achat de document déjà en production (voir `subscription_models.dart`).
class SubscriptionPaymentPendingScreen extends StatefulWidget {
  final InitiatedSubscriptionPurchase purchase;

  const SubscriptionPaymentPendingScreen({super.key, required this.purchase});

  @override
  State<SubscriptionPaymentPendingScreen> createState() => _SubscriptionPaymentPendingScreenState();
}

class _SubscriptionPaymentPendingScreenState extends State<SubscriptionPaymentPendingScreen> {
  late final SubscriptionService _subscriptionService;
  final _referenceController = TextEditingController();

  _Step _step = _Step.reference;
  bool _submitting = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _subscriptionService = SubscriptionService(apiClient: apiClient);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submitReference() async {
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      setState(() => _error = 'Entrez le numéro de reçu reçu après le paiement.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _subscriptionService.submitReference(
        purchaseId: widget.purchase.purchaseId,
        reference: reference,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = _Step.waiting;
      });
      _startPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      });
    }
  }

  void _startPolling() {
    _checkStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    try {
      final status = await _subscriptionService.getStatus(widget.purchase.purchaseId);
      if (!mounted) return;
      if (status.isConfirmed) {
        _pollTimer?.cancel();
        setState(() => _step = _Step.confirmed);
      } else if (status.isFailed) {
        _pollTimer?.cancel();
        setState(() => _step = _Step.failed);
      }
    } catch (_) {
      // Échec de sondage silencieux — on réessaiera au prochain intervalle.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.reference:
        return _buildReferenceStep();
      case _Step.waiting:
        return _buildWaitingStep();
      case _Step.confirmed:
        return _buildConfirmedStep();
      case _Step.failed:
        return _buildFailedStep();
    }
  }

  Widget _buildReferenceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Abonnement ${widget.purchase.plan.label}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.brandBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Payer via ${paymentMethodLabel(widget.purchase.method)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.purchase.instructions, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Numéro', style: TextStyle(color: Colors.black54)),
                  SelectableText(
                    widget.purchase.payTo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Montant', style: TextStyle(color: Colors.black54)),
                  Text(
                    '${widget.purchase.amount.toStringAsFixed(0)} MRU',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Durée', style: TextStyle(color: Colors.black54)),
                  Text(
                    '${widget.purchase.durationDays} jours',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Une fois le paiement effectué sur votre téléphone, collez ci-dessous le numéro de reçu donné par l'application de paiement.",
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (_error != null) ...[
          _ErrorBanner(message: _error!),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _referenceController,
          decoration: const InputDecoration(
            labelText: 'Numéro de reçu',
            prefixIcon: Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _submitReference,
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }

  Widget _buildWaitingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          'Reçu envoyé',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "En attente de confirmation par l'équipe Khatam, après vérification du paiement. Cette page se met à jour automatiquement — vous pouvez aussi revenir plus tard.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _checkStatus,
          icon: const Icon(Icons.refresh),
          label: const Text('Vérifier maintenant'),
        ),
      ],
    );
  }

  Widget _buildConfirmedStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE7F5EC)),
          child: const Icon(Icons.check_circle_outline, color: AppTheme.brandGreen, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Paiement confirmé !',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandGreen,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Votre abonnement ${widget.purchase.plan.label} est maintenant actif.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Retour'),
        ),
      ],
    );
  }

  Widget _buildFailedStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withValues(alpha: 0.08)),
          child: const Icon(Icons.close_rounded, color: Colors.red, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Paiement refusé',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 10),
        const Text(
          "Le paiement n'a pas pu être vérifié. Vérifiez le numéro de reçu ou contactez le support avant de réessayer.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Retour'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
