import 'dart:convert';

class ActivityRecord {
  final String id;
  final String mode;
  final DateTime date;
  final int seconds;
  final double meters;
  final double calories;
  final List<List<double>> points;

  const ActivityRecord({
    required this.id,
    required this.mode,
    required this.date,
    required this.seconds,
    required this.meters,
    required this.calories,
    required this.points,
  });

  double get km => meters / 1000;
  double get paceSecondsPerKm => km > 0 ? seconds / km : 0;

  Map<String, dynamic> toJson() => {
    'id': id, 'mode': mode, 'date': date.toIso8601String(),
    'seconds': seconds, 'meters': meters, 'calories': calories,
    'points': points,
  };

  factory ActivityRecord.fromJson(Map<String, dynamic> json) => ActivityRecord(
    id: json['id'] as String,
    mode: json['mode'] as String,
    date: DateTime.parse(json['date'] as String),
    seconds: (json['seconds'] as num).toInt(),
    meters: (json['meters'] as num).toDouble(),
    calories: (json['calories'] as num).toDouble(),
    points: (json['points'] as List? ?? const [])
      .map((p) => (p as List).map((v) => (v as num).toDouble()).toList())
      .toList(),
  );

  String encode() => jsonEncode(toJson());
}
