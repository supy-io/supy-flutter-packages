/// Detects unsaved changes on editable Flutter surfaces by diffing live state
/// against a captured baseline, and reports what changed.
library;

export 'src/core/baseline_source.dart';
export 'src/core/change_detector.dart';
export 'src/core/change_set.dart';
export 'src/core/change_tracker.dart';
export 'src/core/common_change_kind.dart';
export 'src/core/stream_signal.dart';
export 'src/core/tracked_change.dart';
export 'src/core/tracker_options.dart';
export 'src/detectors/collection_detector.dart';
export 'src/detectors/equality.dart';
export 'src/detectors/facet.dart';
export 'src/detectors/field_group_detector.dart';
export 'src/detectors/membership_detector.dart';
export 'src/detectors/payload_digest_detector.dart';
export 'src/detectors/value_stream_detector.dart';
