class PhoneParser {
  static String clean(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  static String toInternational(String phone) {
    final cleaned = clean(phone);
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('0')) return '+254${cleaned.substring(1)}';
    if (cleaned.startsWith('7') || cleaned.startsWith('1')) return '+254$cleaned';
    return '+254$cleaned';
  }

  static bool isValid(String phone) {
    final cleaned = clean(phone);
    if (cleaned.startsWith('+')) {
      return cleaned.length >= 12 && cleaned.length <= 15;
    }
    return cleaned.length >= 9 && cleaned.length <= 13;
  }
}
