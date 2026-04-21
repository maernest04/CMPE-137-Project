/// Verbal scale for stored noise rating (1–5).
String noiseLevelLabel(int raw) {
  switch (raw.clamp(1, 5)) {
    case 1:
      return 'Silent';
    case 2:
      return 'Quiet';
    case 3:
      return 'Moderate / calm';
    case 4:
      return 'Loud';
    case 5:
      return 'Very loud';
    default:
      return 'Unknown';
  }
}
