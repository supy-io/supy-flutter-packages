import 'dart:async';

import '../flutter_upkeep.dart';

class FlutterUpkeepClient {
  final UpkeepRepository repository;
  final Duration refreshInterval;
  Timer? _updateTimer;
  UpkeepConfig _currentConfig = UpkeepConfig();

  FlutterUpkeepClient({
    required this.repository,
    this.refreshInterval = const Duration(minutes: 5),
  });

  Future<void> initialize() async {
    await _refreshConfiguration();
    _startUpdateTimer();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(
      refreshInterval,
      (_) => _refreshConfiguration(),
    );
  }

  Future<void> _refreshConfiguration() async {
    _currentConfig = await repository.fetchConfiguration();
  }

  MaintenanceConfig? get maintenanceSettings => _currentConfig.maintenance;

  UpdateConfig? get updateSettings => _currentConfig.update;

  bool get inMaintenanceMode => _currentConfig.maintenance?.isActive ?? false;

  // bool requiresForceUpdate(String currentVersion) {
  //   final minVersion = _currentConfig.update?.minimumRequiredVersion;
  //   return minVersion != null
  //       ? _compareSemanticVersions(currentVersion, minVersion) < 0
  //       : false;
  // }
}
