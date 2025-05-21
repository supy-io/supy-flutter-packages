import 'package:flutter_upkeep/src/data/upkeep_repository.dart';

import '../models/upkeep_config.dart';

class MultiSourceUpkeepRepository implements UpkeepRepository {
  final List<UpkeepRepository> _sources;

  MultiSourceUpkeepRepository(Iterable<UpkeepRepository> sources)
      : _sources = sources.toList();

  @override
  Future<UpkeepConfig> fetchConfiguration() async {
    UpkeepConfig? mergedConfig;

    for (final source in _sources) {
      try {
        final config = await source.fetchConfiguration();
        mergedConfig = _mergeConfigurations(mergedConfig, config);
        await source.cacheConfiguration(config);
      } catch (e) {
        // Handle source errors
      }
    }

    return mergedConfig ?? UpkeepConfig();
  }

  UpkeepConfig _mergeConfigurations(UpkeepConfig? existing, UpkeepConfig incoming) {
    return UpkeepConfig(
      maintenance: incoming.maintenance ?? existing?.maintenance,
      update: incoming.update ?? existing?.update,
    );
  }

  @override
  Future<void> cacheConfiguration(UpkeepConfig config) {
    // TODO: implement cacheConfiguration
    throw UnimplementedError();
  }

// ... cache implementation ...
}