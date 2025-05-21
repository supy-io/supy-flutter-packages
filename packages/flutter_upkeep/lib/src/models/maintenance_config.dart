class MaintenanceConfig {
  final bool isActive;
  final String message;
  final DateTime? scheduleEnd;

  MaintenanceConfig({
    required this.isActive,
    required this.message,
    this.scheduleEnd,
  });

  factory MaintenanceConfig.fromJson(Map<String, dynamic> json) =>
      MaintenanceConfig(
        isActive: json['isActive'],
        message: json['message'],
        scheduleEnd: json['scheduleEnd'],
      );
}
