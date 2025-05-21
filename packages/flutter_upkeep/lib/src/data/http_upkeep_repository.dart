import 'dart:convert';

import 'package:flutter_upkeep/src/data/upkeep_repository.dart';
import 'package:flutter_upkeep/src/models/upkeep_config.dart';
import 'package:http/http.dart' as http;

class HttpUpkeepRepository implements UpkeepRepository {
  final String endpoint;

  HttpUpkeepRepository({required this.endpoint});

  @override
  Future<void> cacheConfiguration(UpkeepConfig config) {
    throw UnimplementedError();
  }

  @override
  Future<UpkeepConfig> fetchConfiguration() async {
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
      return UpkeepConfig.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load features');
  }
}
