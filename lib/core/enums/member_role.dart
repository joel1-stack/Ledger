enum MemberRole {
  chairman,
  treasurer,
  secretary,
  member;

  String get label {
    switch (this) {
      case MemberRole.chairman:
        return 'Chairman';
      case MemberRole.treasurer:
        return 'Treasurer';
      case MemberRole.secretary:
        return 'Secretary';
      case MemberRole.member:
        return 'Member';
    }
  }

  static MemberRole fromString(String value) {
    return MemberRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MemberRole.member,
    );
  }
}
