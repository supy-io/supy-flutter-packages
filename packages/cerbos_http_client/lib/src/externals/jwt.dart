class JWT {
  final String jwt;
  final String? keySetId;

  JWT({
    required this.jwt,
    this.keySetId,
  });

  Map<String, dynamic> toMap() {
    return {
      'jwt': jwt,
      'keySetId': keySetId,
    };
  }
}
