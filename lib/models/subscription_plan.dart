class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final Duration duration;
  final bool isSchoolPlan;
  final int maxStudents; // Only applicable for school plans
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.isSchoolPlan = false,
    this.maxStudents = 0,
    required this.features,
  });

  bool get hasAds => id == 'free';
  bool get hasAllGames => id != 'free';
}
