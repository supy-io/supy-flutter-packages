import '../../flutter_upkeep.dart';

abstract class MaintenanceCheckStrategy {
  bool shouldEnableMaintenance(UpkeepConfig config);
}

class DefaultMaintenanceStrategy implements MaintenanceCheckStrategy {
  @override
  bool shouldEnableMaintenance(UpkeepConfig config) {
    final maintenance = config.maintenance;
    if (maintenance == null) return false;

    return maintenance.isActive &&
        (maintenance.scheduleEnd?.isAfter(DateTime.now()) ?? true);
  }
}
