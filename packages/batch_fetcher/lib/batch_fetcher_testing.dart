/// Test doubles for exercising a `BatchFetcher` without real time or a real
/// backend.
///
/// Import this from tests only. It adds no dependencies — there is no
/// `flutter_test` here, so it works under `test` and `flutter_test` alike.
library;

export 'src/testing/fake_clock.dart';
export 'src/testing/recording_observer.dart';
export 'src/testing/scripted_request.dart';
