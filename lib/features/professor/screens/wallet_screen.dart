import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/models/purchase.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

/// Portefeuille professeur : solde, historique des ventes, demandes de
/// retrait. Le déblocage/versement reste toujours géré manuellement par un
/// administrateur (même logique que les paiements élève — voir
/// `khatam-backend/src/routes/wallet.js`).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletService _service;
  late Future<Wallet> _future;

  @override
  void initState() {
    super.initState();
    _service = WalletService(apiClient: context.read<AuthState>().apiClient);
    _future = _service.fetchWallet();
  }

  Future<void> _openWithdrawSheet(num maxAmount) async {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = kPaymentMethods.first;
    String? error;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submit() async {
              final amount = num.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                setSheetState(() => error = 'Montant invalide.');
                return;
              }
              if (amount > maxAmount) {
                setSheetState(() => error = 'Le montant dépasse votre solde disponible.');
                return;
              }
              if (refCtrl.text.trim().isEmpty) {
                setSheetState(() => error = 'Indiquez votre numéro $method.');
                return;
              }
              setSheetState(() {
                submitting = true;
                error = null;
              });
              try {
                await _service.requestWithdraw(
                  amount: amount,
                  method: method,
                  accountRef: refCtrl.text.trim(),
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                setState(() => _future = _service.fetchWallet());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande de retrait envoyée — traitement sous quelques jours.')),
                );
              } on ApiException catch (e) {
                setSheetState(() {
                  submitting = false;
                  error = e.message;
                });
              } catch (e) {
                setSheetState(() {
                  submitting = false;
                  error = 'Impossible de contacter le serveur. Réessayez.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Demande de retrait', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('Solde disponible : ${maxAmount.toStringAsFixed(0)} MRU', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'Moyen de paiement'),
                    items: kPaymentMethods
                        .map((m) => DropdownMenuItem(value: m, child: Text(paymentMethodLabel(m))))
                        .toList(),
                    onChanged: (v) => setSheetState(() => method = v ?? method),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Montant (MRU)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'Votre numéro ${paymentMethodLabel(method)}'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Text('Envoyer la demande'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: FutureBuilder<Wallet>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger le portefeuille.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _future = _service.fetchWallet()),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final wallet = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final next = _service.fetchWallet();
                setState(() => _future = next);
                await next.catchError((_) => wallet);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.brandBlue, AppTheme.brandGreen]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        Text(
                          '${wallet.balance.toStringAsFixed(0)} MRU',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Déjà retiré : ${wallet.withdrawn.toStringAsFixed(0)} MRU',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.brandBlue),
                            onPressed: wallet.balance > 0 ? () => _openWithdrawSheet(wallet.balance) : null,
                            child: const Text('Demander un retrait'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ventes confirmées', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (wallet.sales.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Aucune vente confirmée pour l\'instant.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ...wallet.sales.map((s) => _ListRow(
                          title: s.documentTitle,
                          subtitle: paymentMethodLabel(s.method),
                          trailing: '+${s.amount.toStringAsFixed(0)} MRU',
                          trailingColor: AppTheme.brandGreen,
                        )),
                  const SizedBox(height: 24),
                  const Text('Demandes de retrait', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (wallet.withdrawals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Aucune demande de retrait pour l\'instant.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ...wallet.withdrawals.map((w) => _ListRow(
                          title: '${w.amount.toStringAsFixed(0)} MRU · ${paymentMethodLabel(w.method)}',
                          subtitle: w.accountRef,
                          trailing: w.statusLabel,
                          trailingColor: w.status == 'paid' ? AppTheme.brandGreen : Colors.black54,
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Text(trailing, style: TextStyle(fontWeight: FontWeight.w700, color: trailingColor, fontSize: 13)),
        ],
      ),
    );
  }
}
