import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sd_consultant/src/ui/saved/models/saved_visa_model.dart';

class SavedVisasNotifier extends Notifier<List<SavedVisaItem>> {
  @override
  List<SavedVisaItem> build() => const [];

  /// Checks if a visa with the given identifier or title is saved.
  bool isSaved(String idOrTitle) {
    final query = idOrTitle.trim().toLowerCase();
    if (query.isEmpty) return false;
    return state.any(
      (item) =>
          item.id.trim().toLowerCase() == query ||
          item.title.trim().toLowerCase() == query,
    );
  }

  /// Toggles saved status for an item.
  /// Returns `true` if the item was added, or `false` if it was removed.
  bool toggle(SavedVisaItem item) {
    final queryId = item.id.trim().toLowerCase();
    final queryTitle = item.title.trim().toLowerCase();
    final isAlreadySaved = state.any((i) =>
        (queryId.isNotEmpty && i.id.trim().toLowerCase() == queryId) ||
        (queryTitle.isNotEmpty && i.title.trim().toLowerCase() == queryTitle));

    if (isAlreadySaved) {
      state = state.where((i) {
        final idMatches = queryId.isNotEmpty && i.id.trim().toLowerCase() == queryId;
        final titleMatches = queryTitle.isNotEmpty && i.title.trim().toLowerCase() == queryTitle;
        return !(idMatches || titleMatches);
      }).toList();
      return false;
    } else {
      add(item);
      return true;
    }
  }

  /// Adds a visa to the saved list (placed at the top).
  void add(SavedVisaItem item) {
    final newId = item.id.trim().toLowerCase();
    final newTitle = item.title.trim().toLowerCase();
    final existingIndex = state.indexWhere(
      (i) =>
          (newId.isNotEmpty && i.id.trim().toLowerCase() == newId) ||
          (newTitle.isNotEmpty && i.title.trim().toLowerCase() == newTitle),
    );
    if (existingIndex >= 0) {
      // Already exists, do not duplicate
      return;
    }
    state = [item, ...state];
  }

  /// Removes a visa by identifier or title.
  void remove(String idOrTitle) {
    final query = idOrTitle.trim().toLowerCase();
    if (query.isEmpty) return;
    state = state.where((item) {
      final matches = item.id.trim().toLowerCase() == query ||
          item.title.trim().toLowerCase() == query;
      return !matches;
    }).toList();
  }

  /// Clears all saved visas.
  void clear() {
    state = const [];
  }
}

/// Global provider for the list of saved visas.
final savedVisasProvider =
    NotifierProvider<SavedVisasNotifier, List<SavedVisaItem>>(
  SavedVisasNotifier.new,
);
