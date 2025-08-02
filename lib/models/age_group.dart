enum AgeGroup {
  littleTots(3, 5, 'Little Tots'),
  smartKids(6, 8, 'Smart Kids'),
  youngScholars(9, 12, 'Young Scholars');

  const AgeGroup(this.minAge, this.maxAge, this.displayName);

  final int minAge;
  final int maxAge;
  final String displayName;

  String get description {
    return '$minAge-$maxAge years';
  }

  static AgeGroup fromAge(int age) {
    if (age >= 3 && age <= 5) return AgeGroup.littleTots;
    if (age >= 6 && age <= 8) return AgeGroup.smartKids;
    if (age >= 9 && age <= 12) return AgeGroup.youngScholars;
    return AgeGroup.littleTots; // Default to littleTots for out of range
  }
}
