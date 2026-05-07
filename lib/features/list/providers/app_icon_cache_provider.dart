import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:not_to_do_list/domain/providers/app_picker_api_provider.dart';

/// In-memory LRU cache of PNG bytes, keyed by package name. Capacity 50.
/// CONTEXT.md: "drops on app close; rebuilds on next picker open" → the
/// hosting `Provider` is `autoDispose` so the cache is not leaked across
/// picker sessions. NO disk persistence (T-2-07: keeps the on-disk surface
/// minimal; `android:allowBackup="false"` from Phase 1 covers the rest).
class AppIconLruCache {
  AppIconLruCache({this.capacity = 50});

  final int capacity;
  final LinkedHashMap<String, Uint8List> _store =
      LinkedHashMap<String, Uint8List>();

  Uint8List? get(String key) {
    final v = _store.remove(key);
    if (v != null) {
      _store[key] = v; // move-to-end
    }
    return v;
  }

  void put(String key, Uint8List value) {
    _store
      ..remove(key)
      ..[key] = value;
    while (_store.length > capacity) {
      _store.remove(_store.keys.first);
    }
  }

  int get size => _store.length;
}

final Provider<AppIconLruCache> appIconCacheProvider =
    Provider.autoDispose<AppIconLruCache>(
  (ref) => AppIconLruCache(),
);

/// Fetches PNG bytes for one package, caching via [appIconCacheProvider].
/// Returns null if the package is uninstalled or Kotlin returned null.
final FutureProviderFamily<Uint8List?, String> appIconBytesProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, packageName) async {
    final cache = ref.watch(appIconCacheProvider);
    final cached = cache.get(packageName);
    if (cached != null) {
      return cached;
    }
    final api = ref.watch(appPickerApiProvider);
    final bytes = await api.getApplicationIconPng(packageName);
    if (bytes != null) {
      cache.put(packageName, bytes);
    }
    return bytes;
  },
);
