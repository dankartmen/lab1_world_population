import 'package:equatable/equatable.dart';
import '../models/population_data.dart';

abstract class PopulationState extends Equatable {
  @override
  List<Object> get props => [];
}

class PopulationInitial extends PopulationState {}

class PopulationLoading extends PopulationState {}

class PopulationLoaded extends PopulationState {
  final List<PopulationData> data;
  final Map<String, Map<String, double>> continentPopulation;
  final double correlation;
  final Map<String, double> continentAverages;
  PopulationLoaded({
    required this.data,
    required this.continentPopulation,
    required this.correlation,
    required this.continentAverages
  });

  @override
  List<Object> get props => [data, continentPopulation, correlation];
}

class PopulationError extends PopulationState {
  final String message;

  PopulationError(this.message);

  @override
  List<Object> get props => [message];
}