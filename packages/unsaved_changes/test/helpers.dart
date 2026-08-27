import 'package:unsaved_changes/unsaved_changes_testing.dart';

export 'package:unsaved_changes/unsaved_changes_testing.dart';

/// A synthetic domain, so the engine tests never need a real app's models.
class Doc {
  Doc({required this.title, this.revision = 1});

  String title;
  final int revision;
}

/// Live state the detectors read from.
class Sources {
  Sources({this.title = 'draft'});

  String title;
  final Ticker ticker = Ticker();
}

/// The kit's ticker, under the name these tests already use.
typedef Ticker = TestTicker;

enum Kind { title, other }

/// This suite's detector type, so call sites do not repeat the type arguments.
typedef Scripted = ScriptedDetector<Sources, Kind>;
