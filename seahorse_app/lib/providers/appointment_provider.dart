import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  AppointmentStatus? _filterStatus;
  AppointmentStatus? get filterStatus => _filterStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppointmentModel> get filteredAppointments {
    return _appointments.where((a) {
      if (_filterStatus != null && a.status != _filterStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  int get pendingCount => _appointments.where((a) => a.status == AppointmentStatus.pending).length;
  int get servingCount => _appointments.where((a) => a.status == AppointmentStatus.serving).length;
  int get completedCount => _appointments.where((a) => a.status == AppointmentStatus.completed).length;

  Future<void> loadAppointments(String storeId) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    _appointments = await _service.getAppointments(storeId, date: dateStr);
    _isLoading = false;
    notifyListeners();
  }

  void setDate(DateTime date, String storeId) {
    _selectedDate = date;
    loadAppointments(storeId);
  }

  void setStatusFilter(AppointmentStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<bool> createAppointment({
    required String storeId,
    required String customerName,
    required String phone,
    required String serviceName,
    required double servicePrice,
    required String aptDate,
    required String aptTime,
    String? spaceCode,
    String? spaceName,
    String? staffName,
    int peopleCount = 1,
    String notes = '',
  }) async {
    await _service.createAppointment(
      storeId: storeId,
      customerName: customerName,
      phone: phone,
      serviceName: serviceName,
      servicePrice: servicePrice,
      aptDate: aptDate,
      aptTime: aptTime,
      spaceCode: spaceCode,
      spaceName: spaceName,
      staffName: staffName,
      peopleCount: peopleCount,
      notes: notes,
    );
    await loadAppointments(storeId);
    return true;
  }

  /// 到店核销接待入座 (调用后端原子事务)
  Future<bool> checkIn(int appointmentId, {int? spaceId, String? aptNo, required String storeId}) async {
    final ok = await _service.checkInAppointment(appointmentId, spaceId: spaceId, aptNo: aptNo);
    await loadAppointments(storeId);
    return ok;
  }

  Future<bool> updateStatus(int appointmentId, AppointmentStatus newStatus, String storeId, {String? aptNo}) async {
    final ok = await _service.updateStatus(appointmentId, newStatus, aptNo: aptNo);
    if (ok) {
      await loadAppointments(storeId);
    }
    return ok;
  }

  Future<bool> deleteAppointment(int appointmentId, String storeId) async {
    final ok = await _service.deleteAppointment(appointmentId);
    if (ok) {
      await loadAppointments(storeId);
    }
    return ok;
  }
}
