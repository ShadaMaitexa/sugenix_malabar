class GlucoseRecord {
  final String id;
  final String userId;
  final double value;
  final String type; // 'fasting', 'post_meal', 'random', 'bedtime'
  final DateTime timestamp;
  final String? notes;
  final String? mealType;
  final String? activityLevel;
  final bool isAIFlagged;

  GlucoseRecord({
    required this.id,
    required this.userId,
    required this.value,
    required this.type,
    required this.timestamp,
    this.notes,
    this.mealType,
    this.activityLevel,
    this.isAIFlagged = false,
  });

  factory GlucoseRecord.fromJson(Map<String, dynamic> json) {
    return GlucoseRecord(
      id: json['id'],
      userId: json['userId'],
      value: (json['value'] ?? 0.0).toDouble(),
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      mealType: json['mealType'],
      activityLevel: json['activityLevel'],
      isAIFlagged: json['isAIFlagged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'value': value,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'mealType': mealType,
      'activityLevel': activityLevel,
      'isAIFlagged': isAIFlagged,
    };
  }
}
