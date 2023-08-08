import 'aux_data.dart';
import 'principal.dart';
import 'resource_check.dart';

class CheckResourceRequest extends CheckResourcesRequest {
  CheckResourceRequest({
    required super.principal,
    required ResourceCheck resource,
    super.auxData,
    super.includeMetadata,
    super.requestId,
  }) : super(resources: [resource]);
}

class CheckResourcesRequest {
  CheckResourcesRequest({
    required this.principal,
    this.resources = const [],
    this.auxData,
    this.includeMetadata = false,
    this.requestId,
  });

  final Principal principal;

  final List<ResourceCheck> resources;

  final bool includeMetadata;

  final String? requestId;

  final AuxData? auxData;

  Map<String, dynamic> toMap() {
    return {
      'principal': principal.toMap(),
      'resources': resources.map((e) => e.toMap()).toList(),
      'includeMetadata': includeMetadata,
      if (requestId != null) 'requestId': requestId,
      if (auxData != null) 'auxData': auxData!.toMap(),
    };
  }
}
