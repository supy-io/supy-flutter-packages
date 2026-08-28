import 'package:batch_fetcher/batch_fetcher.dart';
import 'package:batch_fetcher_flutter/src/batch_fetch_notifier.dart';
import 'package:flutter/widgets.dart';

/// Builds from the state of a single id, rebuilding only when *that* id
/// changes.
///
/// A plain `AnimatedBuilder` over the notifier would rebuild every row whenever
/// any id resolved, which in a list of 120 rows is 120 rebuilds per batch. This
/// compares the id's entry and rebuilds only on a real change — the selector
/// pattern, packaged, so a feature does not have to remember it.
class BatchFetchBuilder<TId, TValue> extends StatefulWidget {
  /// Builds for [id] from [source].
  const BatchFetchBuilder({
    required this.source,
    required this.id,
    required this.builder,
    super.key,
  });

  /// The fetcher to watch.
  final BatchFetchListenable<TId, TValue> source;

  /// The id this widget renders.
  final TId id;

  /// Called with the id's current state.
  final Widget Function(BuildContext context, FetchEntry<TValue> entry) builder;

  @override
  State<BatchFetchBuilder<TId, TValue>> createState() =>
      _BatchFetchBuilderState<TId, TValue>();
}

class _BatchFetchBuilderState<TId, TValue>
    extends State<BatchFetchBuilder<TId, TValue>> {
  late FetchEntry<TValue> _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.source.entryOf(widget.id);
    widget.source.addListener(_onChange);
  }

  @override
  void didUpdateWidget(BatchFetchBuilder<TId, TValue> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_onChange);
      widget.source.addListener(_onChange);
    }
    if (oldWidget.source != widget.source || oldWidget.id != widget.id) {
      _entry = widget.source.entryOf(widget.id);
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final next = widget.source.entryOf(widget.id);
    if (next == _entry) return;
    setState(() => _entry = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _entry);
}
