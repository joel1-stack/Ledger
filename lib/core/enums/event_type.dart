enum EventType {
  death,
  wedding,
  emergency,
  project,
  meeting,
  other;

  String get label {
    switch (this) {
      case EventType.death:
        return 'Death';
      case EventType.wedding:
        return 'Wedding';
      case EventType.emergency:
        return 'Emergency';
      case EventType.project:
        return 'Project';
      case EventType.meeting:
        return 'Meeting';
      case EventType.other:
        return 'Other';
    }
  }

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventType.other,
    );
  }
}
