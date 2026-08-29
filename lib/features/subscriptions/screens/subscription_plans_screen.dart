import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/models/purchase.dart' show kPaymentMethods, paymentMethodLabel;
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import 'subscription_payment_pending_screen.dart';

/// Écran "Devenir Basic/Premium" — affiche les deux formules (prix/durée
/// configurés par l'administrateur, jamais codés en dur ici), le plan
/// actuellement actif de l'élève, et lance le même circuit de paiement
/// manuel Bankily/Masrivi/Sedad que pour un document (voir
/// `SubscriptionPaymentPendingScreen`).
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late final SubscriptionService _subscriptionService;

  bool _loading = true;
  String? _loadError;
  SubscriptionPlansInfo? _plans;
  SubscriptionStatusInfo _current = SubscriptionStatusInfo.free();

  bool _busy = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _subscriptionService = SubscriptionService(apiClient: apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _subscriptionService.fetchPlans(),
        _subscriptionService.fetchMe(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as SubscriptionPlansInfo;
        _current = results[1] as SubscriptionStatusInfo;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      });
    }
  }

  Future<void> _chooseMethod(SubscriptionPlanKind plan) async {
    setState(() => _actionError = null);
    final method = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Choisissez un moyen de paiement', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...kPaymentMethods.map(
              (m) => ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.brandBlue),
                title: Text(paymentMethodLabel(m)),
                onTap: () => Navigator.of(sheetContext).pop(m),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (method == null || !mounted) return;
    await _purchase(plan, method);
  }

  Future<void> _purchase(SubscriptionPlanKind plan, String method) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });

    try {
      final purchase = await _subscriptionService.purchase(plan: plan, method: method);
      if (!mounted) return;
      setState(() => _busy = false);

      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SubscriptionPaymentPendingScreen(purchase: purchase),
        ),
      );
      if (!mounted) return;
      _load(); // rafraîchit le plan actuel affiché, qu'il ait été confirmé ou non
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _actionError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _actionError = "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon abonnement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildLoadError()
                : AbsorbPointer(
                    absorbing: _busy,
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: _buildContent(),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final plans = _plans!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CurrentStatusBanner(current: _current),
        const SizedBox(height: 20),
        if (_actionError != null) ...[
          _ErrorBanner(message: _actionError!),
          const SizedBox(height: 16),
        ],
        _PlanCard(
          title: 'Basic',
          color: AppTheme.brandBlue,
          price: plans.basicPrice,
          durationDays: plans.basicDurationDays,
          features: [
            '${plans.basicDiscountPercent.toStringAsFixed(0)}% de réduction sur tous les documents payants',
          ],
          buttonLabel: _current.isPremium
              ? 'Inclus dans Premium'
              : _current.isBasic
                  ? 'Renouveler'
                  : 'Devenir Basic',
          enabled: !_current.isPremium && !_busy,
          onTap: () => _chooseMethod(SubscriptionPlanKind.basic),
        ),
        const SizedBox(height: 16),
        _PlanCard(
          title: 'Premium',
          color: AppTheme.brandGreen,
          price: plans.premiumPrice,
          durationDays: plans.premiumDurationDays,
          features: const [
            "Aucune publicité dans l'application",
            'Accès prioritaire aux nouveaux documents',
          ],
          buttonLabel: _current.isPremium ? 'Renouveler' : 'Devenir Premium',
          enabled: !_busy,
          onTap: () => _chooseMethod(SubscriptionPlanKind.premium),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _CurrentStatusBanner extends StatelessWidget {
  final SubscriptionStatusInfo current;

  const _CurrentStatusBanner({required this.current});

  @override
  Widget build(BuildContext context) {
    final label = current.isPremium ? 'Premium' : (current.isBasic ? 'Basic' : 'Gratuit');
    final color = current.isPremium
        ? AppTheme.brandGreen
        : (current.isBasic ? AppTheme.brandBlue : Colors.black54);
    final expiry = current.expiresAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(current.isFree ? Icons.info_outline : Icons.workspace_premium_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Formule actuelle : $label', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                if (expiry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Valable jusqu'au ${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}",
                    style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final Color color;
  final num price;
  final int durationDays;
  final List<String> features;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.color,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.buttonLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
              const Spacer(),
              Text(
                '${price.toStringAsFixed(0)} MRU',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('pour $durationDays jours', style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13.5))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
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
