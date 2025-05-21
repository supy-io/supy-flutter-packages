import '../../flutter_upkeep.dart';

abstract class UpdateCheckStrategy {
  bool requiresForceUpdate(String currentVersion, UpkeepConfig config);
}

class SemanticVersionUpdateStrategy implements UpdateCheckStrategy {
  @override
  bool requiresForceUpdate(String currentVersion, UpkeepConfig config) {
    final minVersion = config.update?.minimumRequiredVersion;
    if (minVersion == null) return false;

    final comparison = _compareVersionSegments(
      currentVersion.split('.'),
      minVersion.split('.'),
    );

    return comparison < 0;
  }

  int _compareVersionSegments(List<String> current, List<String> required) {
    return 0;
  }
}
