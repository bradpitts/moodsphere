import 'package:uuid/uuid.dart';

class UuidGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a unique v4 UUID string
  static String generate() => _uuid.v4();
}
