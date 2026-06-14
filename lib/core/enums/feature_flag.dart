enum FeatureFlag {
  contributions,
  events,
  approvals,
  reports,
  documents,
  timeline;

  String get key => name;

  static FeatureFlag fromString(String value) {
    return FeatureFlag.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeatureFlag.contributions,
    );
  }
}
