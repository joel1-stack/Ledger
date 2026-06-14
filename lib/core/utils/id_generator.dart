import 'dart:math';

class IdGenerator {
  static final Random _random = Random();

  static String generateInviteCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  static int generateMemberNumber(int max) {
    return max + 1;
  }
}
