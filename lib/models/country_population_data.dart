class CountryPopulationData {
  final String countryName;
  final Map<String, double> yearlyPopulation; // Год -> Население

  CountryPopulationData({
    required this.countryName,
    required this.yearlyPopulation,
  });
}