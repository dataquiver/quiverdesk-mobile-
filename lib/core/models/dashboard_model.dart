import 'package:equatable/equatable.dart';
import 'appointment_model.dart';

class BusinessDashboardModel extends Equatable {
  final String ownerName;
  final String businessName;
  final int todayAppointments;
  final double todayRevenue;
  final int pendingInvoices;
  final int newCustomersThisMonth;
  final List<AppointmentModel> upcomingAppointments;

  const BusinessDashboardModel({
    required this.ownerName,
    required this.businessName,
    required this.todayAppointments,
    required this.todayRevenue,
    required this.pendingInvoices,
    required this.newCustomersThisMonth,
    required this.upcomingAppointments,
  });

  factory BusinessDashboardModel.fromJson(Map<String, dynamic> json) {
    final upcoming = (json['upcomingAppointments'] as List<dynamic>? ?? [])
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return BusinessDashboardModel(
      ownerName: json['ownerName'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      todayAppointments: json['todayAppointments'] as int? ?? 0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingInvoices: json['pendingInvoices'] as int? ?? 0,
      newCustomersThisMonth: json['newCustomersThisMonth'] as int? ?? 0,
      upcomingAppointments: upcoming,
    );
  }

  @override
  List<Object?> get props => [businessName, todayAppointments];
}

class PlatformDashboardModel extends Equatable {
  final int totalBusinesses;
  final int activeSubscriptions;
  final double mrr;
  final int newThisMonth;
  final int trialAccounts;
  final int expiringSoon;

  const PlatformDashboardModel({
    required this.totalBusinesses,
    required this.activeSubscriptions,
    required this.mrr,
    required this.newThisMonth,
    required this.trialAccounts,
    required this.expiringSoon,
  });

  factory PlatformDashboardModel.fromJson(Map<String, dynamic> json) {
    return PlatformDashboardModel(
      totalBusinesses: json['totalBusinesses'] as int? ?? 0,
      activeSubscriptions: json['activeSubscriptions'] as int? ?? 0,
      mrr: (json['mrr'] as num?)?.toDouble() ?? 0.0,
      newThisMonth: json['newThisMonth'] as int? ?? 0,
      trialAccounts: json['trialAccounts'] as int? ?? 0,
      expiringSoon: json['expiringSoon'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalBusinesses, mrr];
}

class StaffDashboardModel extends Equatable {
  final String staffName;
  final int totalToday;
  final int completedToday;
  final int remainingToday;
  final AppointmentModel? nextAppointment;
  final List<AppointmentModel> todayAppointments;

  const StaffDashboardModel({
    required this.staffName,
    required this.totalToday,
    required this.completedToday,
    required this.remainingToday,
    this.nextAppointment,
    required this.todayAppointments,
  });

  factory StaffDashboardModel.fromJson(Map<String, dynamic> json) {
    final list = (json['todayAppointments'] as List<dynamic>? ?? [])
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final next = json['nextAppointment'] != null
        ? AppointmentModel.fromJson(json['nextAppointment'])
        : null;
    return StaffDashboardModel(
      staffName: json['staffName'] as String? ?? '',
      totalToday: json['totalToday'] as int? ?? 0,
      completedToday: json['completedToday'] as int? ?? 0,
      remainingToday: json['remainingToday'] as int? ?? 0,
      nextAppointment: next,
      todayAppointments: list,
    );
  }

  @override
  List<Object?> get props => [staffName, totalToday];
}
