import 'resource.dart';

class ResourceCheck {
  ResourceCheck({
    required this.resource,
    this.actions = const [],
  });

  final Resource resource;
  final List<String> actions;

  Map<String, dynamic> toMap() {
    return {
      'resource': resource.toMap(),
      'actions': actions,
    };
  }
}
