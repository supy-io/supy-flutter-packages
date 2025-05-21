import 'package:flutter_upkeep/flutter_upkeep.dart';

void main() async {
  final upkeepClient = FlutterUpkeepClient(
    repository: MultiSourceUpkeepRepository([
      HttpUpkeepRepository(
        endpoint: 'https://api.yourservice.com/upkeep-config',
      ),
      LocalUpkeepRepository(),
      // FirebaseUpkeepRepository(), // Your custom implementation
    ]),
    refreshInterval: const Duration(minutes: 10),
  );

  await upkeepClient.initialize();

  // if (upkeepClient.inMaintenanceMode) {
  //   showMaintenanceScreen(upkeepClient.maintenanceSettings!);
  // }
  //
  // if (upkeepClient.requiresForceUpdate('1.2.3')) {
  //   showForceUpdateDialog(upkeepClient.updateSettings!);
  // }
}
