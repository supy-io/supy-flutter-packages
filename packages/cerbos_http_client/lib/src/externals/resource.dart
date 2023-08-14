class Resource {
  Resource({
    required this.kind,
    required this.id,
    this.attributes = const {},
    this.policyVersion,
    this.scope,
  });

  final String kind;

  final String id;

  final Map<String, dynamic> attributes;

  final String? policyVersion;

  final String? scope;

  Map<String, dynamic> toMap() {
    return {
      'kind': kind,
      'id': id,
      if (attributes.isNotEmpty) 'attr': attributes,
      if (policyVersion != null) 'policyVersion': policyVersion,
      if (scope != null) 'scope': scope,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      kind: map['kind'] as String,
      id: map['id'] as String,
      attributes: map['attr'] ?? {},
      policyVersion: map['policyVersion'],
      scope: map['scope'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          id == other.id &&
          _attrEquality(other) &&
          policyVersion == other.policyVersion &&
          scope == other.scope;

  bool _attrEquality(Resource other) {
    if (attributes.isEmpty && other.attributes.isEmpty) return true;

    if (attributes.length != other.attributes.length) return false;

    for (final entry in attributes.entries) {
      if (other.attributes[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode =>
      kind.hashCode ^
      id.hashCode ^
      attributes.hashCode ^
      policyVersion.hashCode ^
      scope.hashCode;
}
