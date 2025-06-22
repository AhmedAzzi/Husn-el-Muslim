class CustomDikr {
  String arabic;
  String? benefit;
  String? reference;
  int maxScore;

  CustomDikr({
    required this.arabic,
    this.benefit,
    this.reference,
    this.maxScore = 0,
  });

  factory CustomDikr.fromJson(Map<String, dynamic> json) {
    return CustomDikr(
      arabic: json['arabic'],
      benefit: json['benefit'],
      reference: json['reference'],
      maxScore: json['max_score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'benefit': benefit,
        'reference': reference,
        'max_score': maxScore,
      };
}
