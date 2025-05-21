import '../../flutter_upkeep.dart';

class UpkeepConfig {
  final MaintenanceConfig? maintenance;
  final UpdateConfig? update;

  UpkeepConfig({this.maintenance, this.update});

  factory UpkeepConfig.fromJson(Map<String, dynamic> json) => UpkeepConfig(
    maintenance:
        json['maintenance'] != null
            ? MaintenanceConfig.fromJson(json['maintenance'])
            : null,
    update:
        json['update'] != null ? UpdateConfig.fromJson(json['update']) : null,
  );
}
