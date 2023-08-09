import 'jwt.dart';

class AuxData {
  AuxData({
    required this.jwt,
  });

  final JWT jwt;

  Map<String, dynamic> toMap() {
    return {
      'jwt': jwt.toMap(),
    };
  }
}
