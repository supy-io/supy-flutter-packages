import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:unsaved_changes/src/core/change_detector.dart';
import 'package:unsaved_changes/src/core/tracked_change.dart';

/// The baseline for a [PayloadDigestDetector]: a canonical payload string, or
/// a marker saying the payload cannot be diffed.
@immutable
class PayloadDigest {
  /// A usable digest.
  const PayloadDigest(this.value);

  /// A payload that could not be digested stably.
  const PayloadDigest.unusable() : value = null;

  /// The canonical encoding, or `null` when unusable.
  final String? value;

  /// Whether this digest can be compared against.
  bool get isUsable => value != null;
}

/// A safety net: digests the whole request payload and reports a change when
/// it moves at all.
///
/// Catches edits no named detector knows about, at the cost of not being able
/// to say what changed — so it defaults to [DetectorRole.fallback], and its
/// findings are dropped whenever a named detector fired.
///
/// Add it **last**, after the named detectors. A payload that is not stable
/// between two consecutive reads (timestamps, generated ids) would otherwise
/// report a permanent phantom change; to avoid that, the baseline is captured
/// twice and the detector disables itself if the two disagree.
class PayloadDigestDetector<C, K extends Object>
    extends SnapshotChangeDetector<PayloadDigest, C, K> {
  /// Creates a payload-digest detector.
  PayloadDigestDetector({
    required this.id,
    required this.kind,
    required this.payloadOf,
    this.volatileKeys = const {},
    this.normalize,
    this.role = DetectorRole.fallback,
  });

  @override
  final String id;

  @override
  final DetectorRole role;

  /// Reported when the digest moves.
  final K kind;

  /// Builds the payload to digest.
  final Map<String, dynamic> Function(C sources) payloadOf;

  /// Top-level keys excluded from the digest — the ones the surface changes on
  /// its own, like a status that the save call sets.
  final Set<String> volatileKeys;

  /// Rewrites a leaf value before encoding, for cases the default
  /// canonicalizer treats as different when they are not (`1` vs `1.0`).
  final Object? Function(Object? value)? normalize;

  @override
  PayloadDigest capture(C sources) {
    final first = _digest(sources);
    if (first == null) return const PayloadDigest.unusable();

    final second = _digest(sources);
    if (second != first) return const PayloadDigest.unusable();

    return PayloadDigest(first);
  }

  @override
  Iterable<TrackedChange<K>> compare(PayloadDigest baseline, C sources) {
    if (!baseline.isUsable) return const [];

    final current = _digest(sources);
    if (current == null || current == baseline.value) return const [];

    return [TrackedChange(kind)];
  }

  String? _digest(C sources) {
    try {
      final payload = Map<String, dynamic>.from(payloadOf(sources))
        ..removeWhere((key, _) => volatileKeys.contains(key));

      return jsonEncode(_canonical(payload));
    } on Object {
      return null;
    }
  }

  Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();

      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is Iterable) {
      return [for (final entry in value) _canonical(entry)];
    }

    final leaf = normalize?.call(value) ?? value;
    if (leaf == null || leaf is num || leaf is bool || leaf is String) {
      return leaf;
    }

    return leaf.toString();
  }
}
