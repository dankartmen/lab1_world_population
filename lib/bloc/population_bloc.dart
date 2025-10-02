import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'population_event.dart';
import 'population_state.dart';
import '../models/population_data.dart';

class PopulationBloc extends Bloc<PopulationEvent, PopulationState> {
  PopulationBloc() : super(PopulationInitial()) {
    on<LoadPopulationData>(_onLoadPopulationData);
  }

  Future<void> _onLoadPopulationData(
      LoadPopulationData event, Emitter<PopulationState> emit) async {
    emit(PopulationLoading());
    try {
      // Загрузка CSV из assets
      final csvString = await rootBundle.loadString('assets/world_population.csv');
      
      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString, eol: '\n');

      // Пропускаем заголовок
      List<PopulationData> populationData = csvData.skip(1).map((row) => PopulationData.fromCsv(row)).toList();
      
      debugPrint('Первые 5 строк данных:');
      for (int i = 0; i < min(5, populationData.length); i++) {
        debugPrint('Ранг: ${populationData[i].rank}, Страна: ${populationData[i].country}, Город: ${populationData[i].capital} , Популяция в 2022: ${populationData[i].population2022} , Страна: ${populationData[i].country}, Континент: ${populationData[i].continent}');
      }

      _countEmptyValues(populationData);
      _describe(populationData);

      debugPrint('Уникальные континенты: ${populationData.map((e) => e.continent).toSet()}');
      // Группировка по континентам для круговой диаграммы (2022 год)
      Map<String, Map<String, double>> continentPopulation = {};
      for (var year in ['2022']) {
        Map<String, double> yearData = {};
        for (var continent in populationData.map((e) => e.continent).toSet()) {
          yearData[continent!] = populationData
              .where((e) => e.continent == continent && e.population2022 != null)
              .fold(0.0, (sum, e) => sum + (e.population2022 ?? 0));
        }
        continentPopulation[year] = yearData;
        debugPrint('Найденные континенты: ${yearData.keys.toList()}');
      }

      // Вычисление корреляции между площадью и ростом
      double correlation = _calculateCorrelation(populationData);

      final continentAverages = _calculateContinentAverages(populationData);

      emit(PopulationLoaded(
        data: populationData,
        continentPopulation: continentPopulation,
        correlation: correlation,
        continentAverages: continentAverages
      ));
    } catch (e) {
      emit(PopulationError('Ошибка загрузки данных: $e'));
    }
  }

  
  void _countEmptyValues(List<PopulationData> data) {
    debugPrint('=== ДЕТАЛЬНАЯ СТАТИСТИКА ДАННЫХ ===');
    debugPrint('Всего записей: ${data.length}');
    
    final counters = {
      'Rank': 0,
      'CCA3': 0,
      'Country': 0,
      'Capital': 0,
      'Continent': 0,
      'Population 2022': 0,
      'Population 2020': 0,
      'Population 2015': 0,
      'Population 2010': 0,
      'Population 2000': 0,
      'Population 1990': 0,
      'Population 1980': 0,
      'Population 1970': 0,
      'Area': 0,
      'Density': 0,
      'Growth Rate': 0,
      'World Population %': 0,
    };

    for (var item in data) {
      if (item.rank == null) counters['Rank'] = counters['Rank']! + 1;
      if (item.cca3 == null || item.cca3!.isEmpty) counters['CCA3'] = counters['CCA3']! + 1;
      if (item.country == null || item.country!.isEmpty) counters['Country'] = counters['Country']! + 1;
      if (item.capital == null || item.capital!.isEmpty) counters['Capital'] = counters['Capital']! + 1;
      if (item.continent == null || item.continent!.isEmpty) counters['Continent'] = counters['Continent']! + 1;
      if (item.population2022 == null) counters['Population 2022'] = counters['Population 2022']! + 1;
      if (item.population2020 == null) counters['Population 2020'] = counters['Population 2020']! + 1;
      if (item.population2015 == null) counters['Population 2015'] = counters['Population 2015']! + 1;
      if (item.population2010 == null) counters['Population 2010'] = counters['Population 2010']! + 1;
      if (item.population2000 == null) counters['Population 2000'] = counters['Population 2000']! + 1;
      if (item.population1990 == null) counters['Population 1990'] = counters['Population 1990']! + 1;
      if (item.population1980 == null) counters['Population 1980'] = counters['Population 1980']! + 1;
      if (item.population1970 == null) counters['Population 1970'] = counters['Population 1970']! + 1;
      if (item.area == null) counters['Area'] = counters['Area']! + 1;
      if (item.density == null) counters['Density'] = counters['Density']! + 1;
      if (item.growthRate == null) counters['Growth Rate'] = counters['Growth Rate']! + 1;
      if (item.worldPopulationPercentage == null) counters['World Population %'] = counters['World Population %']! + 1;
    }

    // Вывод результатов
    debugPrint('┌─────────────────────────────────┬──────────┬──────────┐');
    debugPrint('│ Поле                            │ Пустых   │ Заполнено│');
    debugPrint('├─────────────────────────────────┼──────────┼──────────┤');
    
    counters.forEach((field, emptyCount) {
      final filledCount = data.length - emptyCount;
      final filledPercentage = (filledCount / data.length * 100).toStringAsFixed(1);
      debugPrint('│ ${field.padRight(31)} │${emptyCount.toString().padLeft(6)}    │ ${filledPercentage.padLeft(6)}%  │');
    });
    
    debugPrint('└─────────────────────────────────┴──────────┴──────────┘');

  }

  void _describe(List<PopulationData> data) {
    debugPrint('=== Статестическое резюме(describe) ===');
    
    // Заголовок таблицы
    debugPrint('count\tmean\tstd\tmin\t25%\t50%\t75%\tmax');
    
    // Для каждого числового поля
    _describeField(data, 'rank', (item) => item.rank?.toDouble());
    _describeField(data, 'population2022', (item) => item.population2022);
    _describeField(data, 'population2020', (item) => item.population2020);
    _describeField(data, 'population2015', (item) => item.population2015);
    _describeField(data, 'area', (item) => item.area);
    _describeField(data, 'density', (item) => item.density);
    _describeField(data, 'growthRate', (item) => item.growthRate);
    _describeField(data, 'worldPopulationPercentage', (item) => item.worldPopulationPercentage);
  }

  void _describeField(List<PopulationData> data, String fieldName, num? Function(PopulationData) extractor) {
    final values = data.map(extractor).where((value) => value != null).cast<double>().toList();
    
    if (values.isEmpty) return;
    
    values.sort();
    
    final count = values.length;
    final mean = values.reduce((a, b) => a + b) / count;
    final std = _calculateStd(values, mean);
    final min = values.first;
    final max = values.last;
    final q1 = _calculateQuantile(values, 0.25);
    final median = _calculateQuantile(values, 0.50);
    final q3 = _calculateQuantile(values, 0.75);
    
    debugPrint('$fieldName');
    debugPrint('${count.toStringAsFixed(0)}\t${mean.toStringAsFixed(2)}\t${std.toStringAsFixed(2)}\t${min.toStringAsFixed(2)}\t${q1.toStringAsFixed(2)}\t${median.toStringAsFixed(2)}\t${q3.toStringAsFixed(2)}\t${max.toStringAsFixed(2)}');
  }

  double _calculateStd(List<double> values, double mean) {
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double _calculateQuantile(List<double> values, double quantile) {
    final index = (values.length * quantile).round();
    return values[index.clamp(0, values.length - 1)];
  }


  Map<String,Map<String, double>> _calculateContinentAverages(List<PopulationData> data) {
    Map<String,Map<String,List<double>>> continentPopulations = {};
    
    // Определяем все доступные годы
    final years = [
      '2022', '2020', '2015', '2010', '2000', '1990', '1980', '1970'
    ];

    // Собираем данные по каждому году для каждого континента
    for (var item in data) {
      for (var year in years) {
        double? population;
        
        // Получаем значение популяции для текущего года
        switch (year) {
          case '2022': population = item.population2022; break;
          case '2020': population = item.population2020; break;
          case '2015': population = item.population2015; break;
          case '2010': population = item.population2010; break;
          case '2000': population = item.population2000; break;
          case '1990': population = item.population1990; break;
          case '1980': population = item.population1980; break;
          case '1970': population = item.population1970; break;
        }

        if (population != null && item.continent != null) {
          continentPopulations
            .putIfAbsent(item.continent!, () => {})
            .putIfAbsent(year, () => [])
            .add(population);
        }
      }
    }
    
    Map<String,Map<String, double>> averages = {};
    continentPopulations.forEach((continent, yearData) {
      Map<String, double> continentAverages = {};
      yearData.forEach((year,populations) {
        continentAverages[year] = populations.reduce((a, b) => a + b) / populations.length;
      });
      averages[continent] = continentAverages;
    });
    
    return averages;
  }

  double _calculateCorrelation(List<PopulationData> data) {
    List<double> areas = data
        .where((e) => e.area != null && e.growthRate != null && e.area! > 0)
        .map((e) => log(e.area!))
        .toList();
        
    List<double> growthRates = data
        .where((e) => e.area != null && e.growthRate != null && e.area! > 0)
        .map((e) => (e.growthRate! - 1) * 100) // Рост в процентах
        .toList();

    if (areas.isEmpty || growthRates.isEmpty || areas.length != growthRates.length) return 0.0;

    double meanX = areas.reduce((a, b) => a + b) / areas.length;
    double meanY = growthRates.reduce((a, b) => a + b) / growthRates.length;

    double numerator = 0.0;
    double denomX = 0.0;
    double denomY = 0.0;

    for (int i = 0; i < areas.length; i++) {
      double xDiff = areas[i] - meanX;
      double yDiff = growthRates[i] - meanY;
      numerator += xDiff * yDiff;
      denomX += xDiff * xDiff;
      denomY += yDiff * yDiff;
    }

    if (denomX == 0 || denomY == 0) return 0.0;
    
    return numerator / sqrt(denomX * denomY);
  }
}