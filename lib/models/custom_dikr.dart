class CustomDikr {
  String arabic;
  String? benefit;
  String? reference;
  int maxScore;
  int totalCount;
  double autoSpeedSeconds; // Changed to double for seconds representation

  CustomDikr({
    required this.arabic,
    this.benefit,
    this.reference,
    this.maxScore = 0,
    this.totalCount = 0,
    this.autoSpeedSeconds = 1.0, // Default to 1.0 second
  });

  factory CustomDikr.fromJson(Map<String, dynamic> json) {
    double speed = 1.0;
    if (json['auto_speed_seconds'] != null) {
      speed = (json['auto_speed_seconds'] as num).toDouble();
    } else if (json['auto_speed'] != null) {
      speed = (json['auto_speed'] as num).toDouble() / 1000.0;
    }

    return CustomDikr(
      arabic: json['arabic'],
      benefit: json['benefit'],
      reference: json['reference'],
      maxScore: json['max_score'] ?? 0,
      totalCount: json['total_count'] ?? 0,
      autoSpeedSeconds: speed,
    );
  }

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'benefit': benefit,
        'reference': reference,
        'max_score': maxScore,
        'total_count': totalCount,
        'auto_speed_seconds': autoSpeedSeconds,
      };
}
