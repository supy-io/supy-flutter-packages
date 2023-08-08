class Resource {
  Resource({
    required this.kind,
    required this.id,
    this.attributes = const {},
    this.policyVersion,
    this.scope = "",
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
      'attr': attributes,
      'policyVersion': policyVersion,
      'scope': scope,
    };
  }

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      kind: map['kind'] as String,
      id: map['id'] as String,
      attributes: map['attributes'] as Map<String, dynamic>,
      policyVersion: map['policyVersion'] as String,
      scope: map['scope'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          id == other.id &&
          attributes == other.attributes &&
          policyVersion == other.policyVersion &&
          scope == other.scope;

  @override
  int get hashCode =>
      kind.hashCode ^
      id.hashCode ^
      attributes.hashCode ^
      policyVersion.hashCode ^
      scope.hashCode;
}
