/// Une vente confirmée (achat Bankily/Masrivi/Sedad d'un des documents de ce
/// professeur, déjà validé manuellement par un administrateur — voir
/// `GET /api/wallet` côté serveur, table `purchases`).
class WalletSale {
  final String id;
  final num amount;
  final String method;
  final String? confirmedAt;
  final String documentTitle;

  WalletSale({
    required this.id,
    required this.amount,
    required this.method,
    required this.confirmedAt,
    required this.documentTitle,
  });

  factory WalletSale.fromJson(Map<String, dynamic> json) {
    return WalletSale(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?) ?? 0,
      method: json['method'] as String? ?? '',
      confirmedAt: json['confirmedAt'] as String?,
      documentTitle: json['title'] as String? ?? 'Document',
    );
  }
}

/// Une demande de retrait (`POST /api/wallet/withdraw`) — reste "pending"
/// jusqu'à ce qu'un administrateur effectue le virement réel et la marque
/// "paid" (traitement manuel, comme documenté côté serveur).
class WalletWithdrawal {
  final String id;
  final num amount;
  final String method;
  final String accountRef;
  final String status;
  final String? createdAt;

  WalletWithdrawal({
    required this.id,
    required this.amount,
    required this.method,
    required this.accountRef,
    required this.status,
    required this.createdAt,
  });

  factory WalletWithdrawal.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawal(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?) ?? 0,
      method: json['method'] as String? ?? '',
      accountRef: json['accountRef'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'rejected':
        return 'Refusé';
      default:
        return status;
    }
  }
}

/// Portefeuille complet d'un professeur : solde disponible, total déjà
/// retiré, historique des ventes et des demandes de retrait
/// (`GET /api/wallet`).
class Wallet {
  final num balance;
  final num withdrawn;
  final List<WalletSale> sales;
  final List<WalletWithdrawal> withdrawals;

  Wallet({
    required this.balance,
    required this.withdrawn,
    required this.sales,
    required this.withdrawals,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final salesList = (json['sales'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WalletSale.fromJson)
        .toList();
    final withdrawalsList = (json['withdrawals'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WalletWithdrawal.fromJson)
        .toList();
    return Wallet(
      balance: (json['balance'] as num?) ?? 0,
      withdrawn: (json['withdrawn'] as num?) ?? 0,
      sales: salesList,
      withdrawals: withdrawalsList,
    );
  }
}
