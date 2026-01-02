import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class DashboardEvent {}

class DashboardLoadData extends DashboardEvent {}

// States
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> overviewData;
  final Map<String, dynamic> salesData;
  final Map<String, dynamic> ordersData;

   DashboardLoaded({
    required this.overviewData,
    required this.salesData,
    required this.ordersData,
  });
}

class DashboardError extends DashboardState {
  final String message;

   DashboardError(this.message);
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoadData>(_onLoadData);
  }

  Future<void> _onLoadData(
    DashboardLoadData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // TODO: Implement API calls to fetch dashboard data
      // For now, simulate loading with mock data
      await Future.delayed(const Duration(seconds: 2));

      final overviewData = {
        'totalOrders': 1234,
        'totalRevenue': 45678.90,
        'totalUsers': 12543,
        'totalPartners': 89,
      };

      final salesData = {
        'dailySales': [
          {'date': '2024-01-01', 'amount': 1200.50},
          {'date': '2024-01-02', 'amount': 1350.75},
          {'date': '2024-01-03', 'amount': 1180.25},
          // Add more data points
        ],
      };

      final ordersData = {
        'recentOrders': [
          {
            'id': '#12345',
            'customer': 'John Doe',
            'amount': 125.00,
            'status': 'pending',
            'time': '2 min ago',
          },
          {
            'id': '#12344',
            'customer': 'Sarah Ahmed',
            'amount': 89.50,
            'status': 'completed',
            'time': '5 min ago',
          },
        ],
      };

      emit(DashboardLoaded(
        overviewData: overviewData,
        salesData: salesData,
        ordersData: ordersData,
      ));
    } catch (e) {
      emit( DashboardError('Failed to load dashboard data'));
    }
  }
}
