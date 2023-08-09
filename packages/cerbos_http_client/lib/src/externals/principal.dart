class Principal {
  Principal({
    required this.id,
    required this.roles,
    this.attributes = const {},
    this.policyVersion,
    this.scope,
  }) : assert(roles.isNotEmpty);

  final String id;

  final List<String> roles;

  final Map<String, dynamic> attributes;

  final String? policyVersion;

  final String? scope;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roles': roles,
      if (attributes.isNotEmpty) 'attr': attributes,
      if (policyVersion != null) 'policyVersion': policyVersion,
      if (scope != null) 'scope': scope,
    };
  }
}
