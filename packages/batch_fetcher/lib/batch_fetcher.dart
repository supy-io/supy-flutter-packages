/// Coalesces per-item value lookups into batched requests, with debouncing,
/// per-id caching, retry with backoff, and typed per-id state.
library;

export 'src/core/batch_fetcher.dart';
export 'src/core/batch_key.dart';
export 'src/core/batch_outcome.dart';
export 'src/core/batch_scope.dart';
export 'src/core/clock.dart';
export 'src/core/config.dart';
export 'src/core/fetch_entry.dart';
export 'src/core/observer.dart';
export 'src/core/retry_policy.dart';
export 'src/core/settle_policy.dart';
