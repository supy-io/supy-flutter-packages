import 'package:flutter_upkeep/src/data/upkeep_repository.dart';
import 'package:flutter_upkeep/src/models/upkeep_config.dart';

class LocalUpkeepRepository implements UpkeepRepository {
  @override
  Future<void> cacheConfiguration(UpkeepConfig config) {
    // TODO: implement cacheConfiguration
    throw UnimplementedError();
  }

  @override
  Future<UpkeepConfig> fetchConfiguration() {
    // TODO: implement fetchConfiguration
    throw UnimplementedError();
  }
}
