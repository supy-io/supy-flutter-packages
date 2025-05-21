import '../models/upkeep_config.dart';

abstract class UpkeepRepository {
  Future<UpkeepConfig> fetchConfiguration();

  Future<void> cacheConfiguration(UpkeepConfig config) async {}
}
