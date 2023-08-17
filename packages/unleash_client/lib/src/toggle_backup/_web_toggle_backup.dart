import 'package:unleash_client/src/features.dart';
import 'package:unleash_client/src/toggle_backup/toggle_backup.dart';

ToggleBackup create(String backupFilePath) => NoOpToggleBackup();

class NoOpToggleBackup implements ToggleBackup {
  @override
  Future<Features?> load() async => null;

  @override
  Future<void> save(Features toggleJson) => Future.value();
}
