enum AgeGroup {
  toddler(3, 5, 'Little Tots'),
  elementary(6, 8, 'Smart Kids'),
  tween(9, 12, 'Young Scholars');

  const AgeGroup(this.minAge, this.maxAge, this.displayName);

  final int minAge;
  final int maxAge;
  final String displayName;

  String get description {
    return '$minAge-$maxAge years';
  }

  static AgeGroup fromAge(int age) {
    if (age >= 3 && age <= 5) return AgeGroup.toddler;
    if (age >= 6 && age <= 8) return AgeGroup.elementary;
    if (age >= 9 && age <= 12) return AgeGroup.tween;
    return AgeGroup.toddler; // Default to toddler for out of range
  }
}
