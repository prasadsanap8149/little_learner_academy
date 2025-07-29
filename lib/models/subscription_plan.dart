enum PlanType { free, monthly, yearly, school }

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final Duration duration;
  final PlanType type;
  final bool isSchoolPlan;
  final int maxStudents; // Only applicable for school plans
  final List<String> features;
  final String? discountText;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.type,
    this.isSchoolPlan = false,
    this.maxStudents = 0,
    required this.features,
    this.discountText,
    this.isPopular = false,
  });

  bool get hasAds => type == PlanType.free;
  bool get hasAllGames => type != PlanType.free;
  bool get isPremium => type != PlanType.free;

  // Get price per month for comparison
  double get pricePerMonth {
    switch (type) {
      case PlanType.free:
        return 0.0;
      case PlanType.monthly:
        return price;
      case PlanType.yearly:
        return price / 12;
      case PlanType.school:
        return price / maxStudents;
    }
  }

  // Static method to get all available plans
  static List<SubscriptionPlan> get availablePlans => [
    const SubscriptionPlan(
      id: 'free',
      name: 'Free Plan',
      description: 'Perfect for trying out our learning games',
      price: 0.0,
      duration: Duration(days: 365 * 100), // Permanent
      type: PlanType.free,
      features: [
        'Access to 3 basic games',
        'Limited daily play time',
        'Basic progress tracking',
        'Contains ads',
      ],
    ),
    const SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly Premium',
      description: 'Full access to all learning content',
      price: 9.99,
      duration: Duration(days: 30),
      type: PlanType.monthly,
      features: [
        'Access to ALL games and activities',
        'Unlimited play time',
        'Advanced progress tracking',
        'No ads',
        'Offline mode',
        'Priority customer support',
        'Achievement badges',
      ],
    ),
    const SubscriptionPlan(
      id: 'yearly',
      name: 'Yearly Premium',
      description: 'Best value for continuous learning',
      price: 99.99,
      duration: Duration(days: 365),
      type: PlanType.yearly,
      discountText: 'Save 17%',
      isPopular: true,
      features: [
        'Everything in Monthly Premium',
        'Annual savings of \$19.89',
        'Exclusive yearly content',
        'Family sharing (up to 4 children)',
        'Detailed learning reports',
        'Early access to new games',
      ],
    ),
    const SubscriptionPlan(
      id: 'school',
      name: 'School Plan',
      description: 'Designed for educational institutions',
      price: 199.99,
      duration: Duration(days: 365),
      type: PlanType.school,
      isSchoolPlan: true,
      maxStudents: 30,
      features: [
        'Support for up to 30 students',
        'Teacher dashboard',
        'Classroom management tools',
        'Bulk progress reports',
        'Curriculum alignment',
        'Dedicated support',
        'Training sessions',
      ],
    ),
  ];

  // Get plan by ID
  static SubscriptionPlan? getPlanById(String id) {
    try {
      return availablePlans.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration.inDays,
      'type': type.toString().split('.').last,
      'isSchoolPlan': isSchoolPlan,
      'maxStudents': maxStudents,
      'features': features,
      'discountText': discountText,
      'isPopular': isPopular,
    };
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      duration: Duration(days: map['duration'] ?? 0),
      type: PlanType.values.firstWhere(
        (e) => e.toString() == 'PlanType.${map['type']}',
        orElse: () => PlanType.free,
      ),
      isSchoolPlan: map['isSchoolPlan'] ?? false,
      maxStudents: map['maxStudents'] ?? 0,
      features: List<String>.from(map['features'] ?? []),
      discountText: map['discountText'],
      isPopular: map['isPopular'] ?? false,
    );
  }
}
