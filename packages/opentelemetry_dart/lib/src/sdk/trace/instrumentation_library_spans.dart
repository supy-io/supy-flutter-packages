import '../instrumentation_library.dart';
import 'span.dart';

class InstrumentationLibrarySpans {
  final InstrumentationLibrary instrumentationLibrary;
  final List<Span> spans;
  final String? schemaUrl;

  InstrumentationLibrarySpans({
    required this.instrumentationLibrary,
    this.spans = const [],
    this.schemaUrl,
  });
}
