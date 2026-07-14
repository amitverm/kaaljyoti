/// The three supported rendering styles for a rashi chart.
enum ChartStyle {
  north,
  south,
  circular;

  String get displayName => switch (this) {
        north => 'North Indian',
        south => 'South Indian',
        circular => 'Circular',
      };
}
