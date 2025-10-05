class HistogramFeature {
  /// Отображаемое название (например: "Население 2022")
  final String title;
  /// Название поля в модели PopulationData (например: "population2022")
  final String field;
  /// Делитель для нормализации значений (например: 1e6 для миллионов)
  final double divisor;
  /// Единица измерения (например: "млн", "тыс. км²")
  final String unit;

  HistogramFeature(this.title, this.field, this.divisor, this.unit);
}