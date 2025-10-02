import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bloc/population_bloc.dart';
import '../bloc/population_event.dart';
import '../bloc/population_state.dart';
import '../models/country_population_data.dart';
import '../models/interactive_spots.dart';
import '../models/population_data.dart';

class PopulationScreen extends StatelessWidget {
  const PopulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PopulationBloc()..add(LoadPopulationData()),
      child: Scaffold(
        appBar: AppBar(title: Text('Анализ населения')),
        body: BlocBuilder<PopulationBloc, PopulationState>(
          builder: (context, state) {
            if (state is PopulationLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is PopulationLoaded) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Статистика
                    _buildStatistics(state),
                    // Круговая диаграмма (2022 год)
                    _buildPieChart(state),
                    // Парные диаграммы
                    _buildPairPlotChart(state),
                    // Сравнение роста населения Индии и Китая
                    _buildChinaIndiaComparison(state),
                    // Сравнение населения Франции и Японии
                    _buildFranceJapanCompression(state),
                    // Диаграмма рассеяния: площадь vs рост
                    _buildScatterChart(state),
                    // Гистограмма населения по годам
                    _buildPopulationHistogram(state),
                    // График среднего населения по континентам
                    _buildContinentChart(state),
                  ],
                ),
              );
            } else if (state is PopulationError) {
              return Center(child: Text(state.message));
            }
            return Center(child: Text('Нажмите для загрузки данных'));
          },
        ),
      ),
    );
  }

  

  Widget _buildStatistics(PopulationLoaded state) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика данных',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Количество стран: ${state.data.length}'),
            Text('Корреляция площади и роста: ${state.correlation.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  
  Widget _buildPieChart(PopulationLoaded state) {
    final yearData = state.continentPopulation['2022'];
    if (yearData == null || yearData.isEmpty) {
      return Container();
    }

    // Отладочная информация для проверки данных
    debugPrint('Данные по континентам: $yearData');

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Распределение населения по континентам (2022)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: yearData.entries.map((e) => PieChartSectionData(
                          color: _getColor(e.key),
                          value: e.value,
                          radius: 60,
                          title: '',
                        )).toList(),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildLegend(yearData),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data) {
    final total = data.values.reduce((a, b) => a + b);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final continentName = _abbreviateContinent(entry.key);
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  continentName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScatterChart(PopulationLoaded state) {
    // Создаем интерактивные точки с данными о странах
    final interactiveSpots = state.data.where((e) => 
      e.area != null && 
      e.area! > 100 && 
      e.area! < 1000000 &&
      e.growthRate != null &&
      e.population2022 != null
    ).map((e) => InteractiveSpot(
      spot: ScatterSpot(
        e.area! / 1000, // в тысячах км²
        (e.growthRate! - 1) * 100, // в процентах
      ),
      countryName: e.country!,
      area: e.area!,
      growthRate: e.growthRate!,
      population: e.population2022!,
    )).toList();

    if (interactiveSpots.isEmpty) return Container();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Корреляция: Площадь vs Рост населения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Наведите на точку для информации о стране',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: interactiveSpots.map((e) => e.spot).toList(),
                  minX: 0,
                  maxX: 1000,
                  minY: -10,
                  maxY: 10,
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipItems: (ScatterSpot touchedSpot) {
                        // Находим соответствующую интерактивную точку
                        final interactiveSpot = interactiveSpots.firstWhere(
                          (spot) => spot.spot.x == touchedSpot.x && spot.spot.y == touchedSpot.y,
                          orElse: () => interactiveSpots.first,
                        );
                        
                        return ScatterTooltipItem(
                          '${interactiveSpot.countryName}\n'
                          'Площадь: ${(interactiveSpot.area).round()} км²\n'
                          'Рост: ${((interactiveSpot.growthRate - 1) * 100).toStringAsFixed(1)}%\n'
                          'Население: ${(interactiveSpot.population / 1e6).toStringAsFixed(1)} млн',
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 2,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 200,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}k км²'),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFranceJapanCompression(PopulationLoaded state){
    final selectedCountries = ['France', 'Japan'];
    
    final pairPlotData = _preparePairPlotData(state.data, selectedCountries);
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Население Франции и Японии за разные годы',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 800,
              height: 400,
              child: _buildFranceJapanComparisonChart(pairPlotData),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFranceJapanComparisonChart(List<CountryPopulationData> data) {
    final years = ['1970', '1980', '1990', '2000', '2010', '2015', '2020', '2022'];
    
    if (data.length < 2) return Container();

    final franceData = data.firstWhere(
      (e) => e.countryName == 'France',
      orElse: () => data.firstWhere(
        (e) => e.countryName.toLowerCase().contains('france'),
      ),
    );
    
    final japanData = data.firstWhere(
      (e) => e.countryName == 'Japan',
      orElse: () => data.firstWhere(
        (e) => e.countryName.toLowerCase().contains('japan'),
      ),
    );

    final franceSpots = years.map((year) {
      final population = franceData.yearlyPopulation[year] ?? 0;
      return FlSpot(years.indexOf(year).toDouble(), population / 1e6); // в миллионах
    }).toList();

    final japanSpots = years.map((year) {
      final population = japanData.yearlyPopulation[year] ?? 0;
      return FlSpot(years.indexOf(year).toDouble(), population / 1e6);
    }).toList();

    // Находим максимальное значение для установки границ графика
    final maxFrance = franceData.yearlyPopulation.values.reduce((a, b) => a > b ? a : b) / 1e6;
    final maxJapan = japanData.yearlyPopulation.values.reduce((a, b) => a > b ? a : b) / 1e6;
    final maxY = (maxFrance > maxJapan ? maxFrance : maxJapan) * 1.1;

    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < years.length) {
                          return Text(
                            years[value.toInt()],
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: _calculateFranceJapanInterval(maxY),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}M',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: franceSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: japanSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
          SizedBox(height: 16),
          // Легенда
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Text('Франция', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text('Япония', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateFranceJapanInterval(double maxY) {
    if (maxY > 150) return 50;
    if (maxY > 100) return 25;
    if (maxY > 50) return 10;
    return 5;
  }

  Widget _buildPopulationHistogram(PopulationLoaded state) {
    // Берем топ-20 стран по населению
    final sortedCountries = state.data
        .where((e) => e.population2022 != null)
        .toList();
    
    sortedCountries.sort((a, b) => (b.population2022 ?? 0).compareTo(a.population2022 ?? 0));
    
    final topCountries = sortedCountries.length > 20 
        ? sortedCountries.sublist(0, 20)
        : sortedCountries;

    if (topCountries.isEmpty) return Container();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Топ-${topCountries.length} стран по населению (2022)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: topCountries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final country = entry.value;
                    final population = country.population2022! / 1e6; // в миллионах
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: population,
                          color: _getColorForIndex(index),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < topCountries.length) {
                            final country = topCountries[index];
                            final shortName = _shortenCountryName(country.country!);
                            return SideTitleWidget(
                              meta: meta,
                              child: Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    shortName,
                                    style: TextStyle(fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Text('');
                        },
                        reservedSize: 60, // Увеличиваем место для подписей
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 300,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}M'),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final country = topCountries[groupIndex];
                        return BarTooltipItem(
                          '${country.country}\n${(country.population2022! / 1e6).toStringAsFixed(1)} млн человек',
                          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _shortenCountryName(String name) {
    if (name.length <= 12) return name;
    final parts = name.split(' ');
    if (parts.length > 1) {
      return parts.map((p) => p[0]).join('').toUpperCase();
    }
    return '${name.substring(0, 10)}...';
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Widget _buildContinentChart(PopulationLoaded state) {
    final continentAverages = state.continentAverages;
    
    // Получаем все годы из данных (берем у первого континента)
    final years = continentAverages.values.first.keys.toList();
    years.sort(); // Сортируем годы
    
    // Получаем все континенты
    final continents = continentAverages.keys.toList();
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Среднее население по континентам по годам',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < years.length) {
                            return Text(years[value.toInt()], style: TextStyle(fontSize: 10));
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}M'),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: continents.map((continent) {
                    final data = continentAverages[continent]!;
                    final spots = years.asMap().entries.map((entry) {
                      final index = entry.key;
                      final year = entry.value;
                      final population = data[year] ?? 0;
                      return FlSpot(index.toDouble(), population / 1e6); // в миллионах
                    }).toList();
                    
                    return LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: _getColor(continent),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    );
                  }).toList(),
                  minY: 0,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Легенда
            Wrap(
              spacing: 16,
              children: continents.map((continent) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getColor(continent),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _abbreviateContinent(continent),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairPlotChart(PopulationLoaded state) {
    // Выбираем страны для сравнения (можно сделать выбор пользователем)
    final selectedCountries = ['China', 'India', 'United States', 'Russia', 'Germany', 'Italy'];
    
    final pairPlotData = _preparePairPlotData(state.data, selectedCountries);
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Сравнение населения стран за разные годы',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Парные диаграммы',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 800,
              height: 500,
              child: _buildPairPlotChartContent(pairPlotData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChinaIndiaComparison(PopulationLoaded state) {
    // Выбираем страны для сравнения (можно сделать выбор пользователем)
    final selectedCountries = ['China', 'India'];
    
    final pairPlotData = _preparePairPlotData(state.data, selectedCountries);
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: 800,
              height: 500,
              child: _build2CountryComparsionChart(pairPlotData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairPlotChartContent(List<CountryPopulationData> data) {
    final years = ['1970', '1980', '1990', '2000', '2010', '2015', '2020', '2022'];
    
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        SizedBox(
          width: 800, // Ширина для всех диаграмм
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 2 колонки
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return _buildCountryChart(data[index], years);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryChart(CountryPopulationData countryData, List<String> years) {
    final spots = years.map((year) {
      final population = countryData.yearlyPopulation[year] ?? 0;
      return FlSpot(years.indexOf(year).toDouble(), population / 1e6); // в миллионах
    }).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            _shortenCountryName(countryData.countryName),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < years.length) {
                          return Text(years[value.toInt()], style: TextStyle(fontSize: 8));
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _calculateChartInterval(countryData),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}M',
                        style: TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _getColorForCountry(countryData.countryName),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2CountryComparsionChart(List<CountryPopulationData> data) {
    final years = ['1970', '1980', '1990', '2000', '2010', '2015', '2020', '2022'];
    if (data.length < 2) return Container();

    final chinaData = data.firstWhere((e) => e.countryName == 'China');
    final indiaData = data.firstWhere((e) => e.countryName == 'India');

    final chinaSpots = years.map((year) {
      final population = chinaData.yearlyPopulation[year] ?? 0;
      return FlSpot(years.indexOf(year).toDouble(), population / 1e6);
    }).toList();

    final indiaSpots = years.map((year) {
      final population = indiaData.yearlyPopulation[year] ?? 0;
      return FlSpot(years.indexOf(year).toDouble(), population / 1e6);
    }).toList();

    final maxChina = chinaData.yearlyPopulation.values.reduce((a, b) => a > b ? a : b) / 1e6;
    final maxIndia = indiaData.yearlyPopulation.values.reduce((a, b) => a > b ? a : b) / 1e6;
    final maxY = (maxChina > maxIndia ? maxChina : maxIndia) * 1.1;

    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            'Китай vs Индия',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.red,
                ),
                SizedBox(width: 4),
                Text('Китай', style: TextStyle(fontSize: 10)),
              ],
            ),
            SizedBox(width: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.blue,
                ),
                SizedBox(width: 4),
                Text('Индия', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < years.length) {
                        return Text(years[value.toInt()], style: TextStyle(fontSize: 8));
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: _calculateComparisonInterval(maxY),
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}M',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: chinaSpots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: indiaSpots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              minY: 0,
              maxY: maxY,
            ),
          ),
        ),
      ],
    ),
  );
}

double _calculateComparisonInterval(double maxY) {
  if (maxY > 1000) return 200;
  if (maxY > 500) return 100;
  if (maxY > 200) return 50;
  return 20;
}

  // Вспомогательные методы
  List<CountryPopulationData> _preparePairPlotData(List<PopulationData> allData, List<String> selectedCountries) {
    final result = <CountryPopulationData>[];
    
    for (final countryName in selectedCountries) {
      final countryData = allData.firstWhere(
        (data) => data.country == countryName,
        orElse: () => allData.firstWhere(
          (data) => data.country?.toLowerCase().contains(countryName.toLowerCase()) ?? false,
        ),
      );
      
      final yearlyPopulation = {
        '1970': countryData.population1970 ?? 0,
        '1980': countryData.population1980 ?? 0,
        '1990': countryData.population1990 ?? 0,
        '2000': countryData.population2000 ?? 0,
        '2010': countryData.population2010 ?? 0,
        '2015': countryData.population2015 ?? 0,
        '2020': countryData.population2020 ?? 0,
        '2022': countryData.population2022 ?? 0,
      };
      
      result.add(CountryPopulationData(
        countryName: countryName,
        yearlyPopulation: yearlyPopulation,
      ));
    }
    
    return result;
  }

  double _calculateChartInterval(CountryPopulationData countryData) {
    final maxPopulation = countryData.yearlyPopulation.values.reduce((a, b) => a > b ? a : b) / 1e6;
    if (maxPopulation > 1000) return 200;
    if (maxPopulation > 500) return 100;
    if (maxPopulation > 200) return 50;
    return 20;
  }

  Color _getColorForCountry(String country) {
    final colors = {
      'China': Colors.red,
      'India': Colors.blue,
      'United States': Colors.green,
      'Russia': Colors.orange,
      'Germany': Colors.purple,
      'Japan': Colors.teal,
      'Brazil': Colors.pink,
      'Nigeria': Colors.indigo,
    };
    final random = Random();
    return colors[country] ?? Color.fromARGB(120,random.nextInt(255),random.nextInt(255),random.nextInt(255));
  }

  List<BarChartGroupData> _createHistogramData(List<double> populations) {
    if (populations.isEmpty) return [];
    
    final maxPopulation = populations.reduce((a, b) => a > b ? a : b);
    final binCount = 10;
    final binWidth = maxPopulation / binCount;
    
    List<int> bins = List.generate(binCount, (_) => 0);
    
    for (double population in populations) {
      int binIndex = (population / binWidth).floor();
      if (binIndex >= binCount) binIndex = binCount - 1;
      bins[binIndex]++;
    }
    
    return bins.asMap().entries.map((entry) => BarChartGroupData(
      x: entry.key,
      barRods: [BarChartRodData(toY: entry.value.toDouble(), color: Colors.blue)],
    )).toList();
  }

  String _abbreviateContinent(String continent) {
    // Приводим к нижнему регистру для унификации сравнения
    final continentLower = continent.toLowerCase();
    
    final abbreviations = {
      'africa': 'Африка',
      'asia': 'Азия', 
      'europe': 'Европа',
      'north america': 'Сев. Америка',
      'south america': 'Юж. Америка',
      'oceania': 'Океания',
      'others': 'Другие',
    };
    
    // Ищем соответствие (включая частичное совпадение)
    for (var key in abbreviations.keys) {
      if (continentLower.contains(key)) {
        return abbreviations[key]!;
      }
    }
    
    // Если не нашли, возвращаем оригинальное название
    return continent;
  }

  Color _getColor(String continent) {
    // Приводим к нижнему регистру для унификации
    final continentLower = continent.toLowerCase();
    
    if (continentLower.contains('africa')) return Colors.blue;
    if (continentLower.contains('asia')) return Colors.red;
    if (continentLower.contains('europe')) return Colors.green;
    if (continentLower.contains('north america')) return Colors.yellow;
    if (continentLower.contains('south america')) return Colors.purple;
    if (continentLower.contains('oceania')) return Colors.orange;
    
    // Генерируем цвет на основе хэша строки для неизвестных континентов
    return Colors.primaries[continent.hashCode % Colors.primaries.length];
  }
}