import '../../../core/api/api_client.dart';
import '../models/wallet.dart';

/// Portefeuille professeur — contrat vérifié dans
/// `khatam-backend/src/routes/wallet.js`.
class WalletService {
  final ApiClient apiClient;

  WalletService({required this.apiClient});

  Future<Wallet> fetchWallet() async {
    final data = await apiClient.get('/wallet');
    return Wallet.fromJson(data);
  }

  /// [method] doit être l'un de : bankily, masrivi, sedad (minuscules).
  /// Le serveur refuse tout montant supérieur au solde disponible
  /// (`INVALID_AMOUNT`).
  Future<WalletWithdrawal> requestWithdraw({
    required num amount,
    required String method,
    required String accountRef,
  }) async {
    final data = await apiClient.post('/wallet/withdraw', {
      'amount': amount,
      'method': method,
      'accountRef': accountRef,
    });
    return WalletWithdrawal.fromJson(data['withdrawal'] as Map<String, dynamic>);
  }
}
