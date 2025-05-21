class UpdateConfig {
  final String currentVersion;
  final String minimumRequiredVersion;
  final String? releaseNotes;

  UpdateConfig({
    required this.currentVersion,
    required this.minimumRequiredVersion,
    this.releaseNotes,
  });

  factory UpdateConfig.fromJson(Map<String, dynamic> json) => UpdateConfig(
    currentVersion: json['currentVersion'],
    minimumRequiredVersion: json['minimumRequiredVersion'],
    releaseNotes: json['releaseNotes'],
  );
}