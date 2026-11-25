import 'dart:convert';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/ui/profile/models/saved_payment_method_model.dart';
import 'package:flutter_sd_consultant/src/ui/profile/models/transaction_record_model.dart';

const String _kTransactionsPrefKey = 'sb_user_transaction_history_v1';
const String _kPaymentMethodsPrefKey = 'sb_user_saved_payment_methods_v1';

/// Manages the real transaction records for the user.
/// Defaults to an empty list until the user actually completes a transaction.
class TransactionHistoryNotifier extends StateNotifier<List<TransactionRecord>> {
  TransactionHistoryNotifier() : super(const []) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kTransactionsPrefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        final items = decoded
            .map((item) => TransactionRecord.fromJson(item as Map<String, dynamic>))
            .toList();
        state = items;
      }
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_kTransactionsPrefKey, encoded);
    } catch (_) {}
  }

  /// Records a new real transaction upon checkout or payment confirmation.
  void recordTransaction(TransactionRecord tx) {
    // Avoid duplicate recording of same reference
    if (state.any((existing) => existing.referenceId == tx.referenceId && existing.id == tx.id)) {
      return;
    }
    state = [tx, ...state];
    _saveToCache();
  }

  /// Clears transaction history
  void clearHistory() {
    state = const [];
    _saveToCache();
  }
}

/// Global provider for real user transaction history.
final StateNotifierProvider<TransactionHistoryNotifier, List<TransactionRecord>> transactionHistoryProvider =
    StateNotifierProvider<TransactionHistoryNotifier, List<TransactionRecord>>(
  (ref) => TransactionHistoryNotifier(),
);

/// Manages real tokenized payment methods saved by the user.
/// Defaults to an empty list (no hardcoded mock cards).
class SavedPaymentMethodsNotifier extends StateNotifier<List<SavedPaymentMethod>> {
  SavedPaymentMethodsNotifier() : super(const []) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kPaymentMethodsPrefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        final items = decoded
            .map((item) => SavedPaymentMethod.fromJson(item as Map<String, dynamic>))
            .toList();
        state = items;
      }
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_kPaymentMethodsPrefKey, encoded);
    } catch (_) {}
  }

  /// Saves a new payment card or account
  void addMethod(SavedPaymentMethod method) {
    final isFirst = state.isEmpty;
    final newMethod = method.copyWith(isDefault: isFirst || method.isDefault);
    state = [...state.map((m) => newMethod.isDefault ? m.copyWith(isDefault: false) : m), newMethod];
    _saveToCache();
  }

  /// Deletes a saved payment method
  void removeMethod(String id) {
    state = state.where((m) => m.id != id).toList();
    if (state.isNotEmpty && !state.any((m) => m.isDefault)) {
      state = [state.first.copyWith(isDefault: true), ...state.skip(1)];
    }
    _saveToCache();
  }

  /// Sets a payment method as default
  void setDefault(String id) {
    state = [
      for (final m in state) m.copyWith(isDefault: m.id == id),
    ];
    _saveToCache();
  }
}

/// Global provider for user's saved payment methods.
final StateNotifierProvider<SavedPaymentMethodsNotifier, List<SavedPaymentMethod>> savedPaymentMethodsProvider =
    StateNotifierProvider<SavedPaymentMethodsNotifier, List<SavedPaymentMethod>>(
  (ref) => SavedPaymentMethodsNotifier(),
);

/// Helper to record a new transaction globally from anywhere in the app
void recordAppTransaction(
  WidgetRef ref, {
  required String title,
  required String amount,
  required String referenceId,
  required String paymentMethod,
  String status = 'completed',
  String? applicationRef,
  String? category,
}) {
  final tx = TransactionRecord(
    id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    amount: amount,
    date: DateTime.now(),
    referenceId: referenceId,
    paymentMethod: paymentMethod,
    status: status,
    applicationRef: applicationRef,
    category: category,
  );
  ref.read(transactionHistoryProvider.notifier).recordTransaction(tx);
}
