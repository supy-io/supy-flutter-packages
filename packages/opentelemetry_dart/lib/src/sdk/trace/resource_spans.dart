import '../resource/resource.dart';
import 'instrumentation_library_spans.dart';

class ResourceSpans {
  final Resource resource;
  final List<InstrumentationLibrarySpans> instrumentationLibrarySpans;

  ResourceSpans({
    required this.resource,
    this.instrumentationLibrarySpans = const [],
  });
}
