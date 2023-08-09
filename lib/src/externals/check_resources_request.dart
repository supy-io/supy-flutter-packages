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
    this.includeMetadata,
    this.requestId,
  });

  final Principal principal;

  final List<ResourceCheck> resources;

  final bool? includeMetadata;

  final String? requestId;

  final AuxData? auxData;

  Map<String, dynamic> toMap() {
    return {
      if (requestId != null) 'requestId': requestId,
      'principal': principal.toMap(),
      'resources': resources.map((e) => e.toMap()).toList(),
      if (includeMetadata != null) 'includeMeta': includeMetadata,
      if (auxData != null) 'auxData': auxData!.toMap(),
    };
  }
}
