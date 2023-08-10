import 'resource.dart';

const _effectMapper = {
  'EFFECT_ALLOW': Effect.allow,
  'EFFECT_DENY': Effect.deny,
};

enum Effect {
  allow,
  deny,
}

class CheckResourcesResponse {
  final String? requestId;
  final List<CheckResourceResult> results;

  CheckResourcesResponse({
    this.requestId,
    this.results = const [],
  });

  factory CheckResourcesResponse.fromMap(Map<String, dynamic> map) {
    return CheckResourcesResponse(
      requestId: map['requestId'],
      results: (map['results'] as List)
          .map((e) => CheckResourceResult.fromMap(e))
          .toList(),
    );
  }

  CheckResourceResult? findResult(Resource resource) {
    for (CheckResourceResult r in results) {
      if (r.resource == resource) {
        return r;
      }
    }

    return null;
  }
}

class CheckResourceResponse {
  final String? requestId;
  final CheckResourceResult result;

  CheckResourceResponse({
    this.requestId,
    required this.result,
  });

  factory CheckResourceResponse.fromMap(Map<String, dynamic> map) {
    return CheckResourceResponse(
      requestId: map['requestId'],
      result: (map['results'] as List)
          .map((e) => CheckResourceResult.fromMap(e))
          .toList()
          .first,
    );
  }
}

class CheckResourceResult {
  final Resource resource;
  final List<Action> actions;

  CheckResourceResult({
    required this.resource,
    required this.actions,
  });

  factory CheckResourceResult.fromMap(Map<String, dynamic> map) {
    return CheckResourceResult(
      resource: Resource.fromMap(map['resource']),
      actions: (map['actions'] as Map<String, dynamic>)
          .entries
          .map(
            (e) => Action._fromEntry(e),
          )
          .toList(),
    );
  }

  bool isAllAllowed() => actions.every((e) => e.isAllowed());

  List<Action> allowedActions() => actions.where((e) => e.isAllowed()).toList();
}

class Action {
  Action({
    required this.effect,
    required this.name,
  });

  final String name;
  final Effect effect;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'effect': effect.name,
    };
  }

  bool isAllowed() {
    return effect == Effect.allow;
  }

  factory Action._fromEntry(MapEntry<String, dynamic> entry) {
    return Action(
      name: entry.key,
      effect: _effectMapper[entry.value]!,
    );
  }
}
