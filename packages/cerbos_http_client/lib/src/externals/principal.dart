class Principal {
  Principal({
    required this.id,
    this.roles = const [],
    this.attributes = const {},
    this.policyVersion,
    this.scope,
  });

  final String id;

  final List<String> roles;

  final Map<String, dynamic> attributes;

  final String? policyVersion;

  final String? scope;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (roles.isNotEmpty) 'roles': roles,
      if (attributes.isNotEmpty) 'attr': attributes,
      if (policyVersion != null) 'policyVersion': policyVersion,
      if (scope != null) 'scope': scope,
    };
  }
}
