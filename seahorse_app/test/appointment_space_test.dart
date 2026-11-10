import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/core/constants/constants.dart';
import 'package:seahorse_app/models/appointment_model.dart';
import 'package:seahorse_app/models/space_model.dart';

void main() {
  group('Appointment & Space Workflow Tests', () {
    test('1. Appointment status transitions and verification', () {
      final apt = AppointmentModel(
        id: 101,
        aptNo: 'APT-2026-001',
        storeId: 'S001',
        customerName: '王女士',
        phone: '13812345678',
        serviceName: '精油舒压开背',
        servicePrice: 268.0,
        aptDate: '2026-09-14',
        aptTime: '15:00',
        status: AppointmentStatus.pending,
      );

      expect(apt.status, AppointmentStatus.pending);
      expect(apt.status.label, '待到店');

      // Customer arrives -> status changes to serving
      apt.status = AppointmentStatus.serving;
      expect(apt.status, AppointmentStatus.serving);
      expect(apt.status.label, '服务中');

      // Service completed
      apt.status = AppointmentStatus.completed;
      expect(apt.status, AppointmentStatus.completed);
      expect(apt.status.label, '已完成');
    });

    test('2. Space status transitions and service billing calculation', () {
      final space = SpaceModel(
        id: 1,
        storeId: 'S001',
        spaceCode: 'V01',
        spaceName: '玉衡养生坊',
        spaceType: 'ROOM',
        hourlyFee: 100.0,
        status: SpaceStatus.idle,
      );

      expect(space.status, SpaceStatus.idle);
      expect(space.status.label, '空闲可用');

      // Open room / start service
      space.status = SpaceStatus.occupied;
      space.currentCustomerName = '刘先生';
      space.currentSessionId = 999;
      space.serviceStartTime = DateTime.now().subtract(const Duration(minutes: 90));
      space.currentBillAmount = 150.0 + 88.0; // Room fee + tea

      expect(space.status, SpaceStatus.occupied);
      expect(space.status.label, '在场服务中');
      expect(space.servedMinutes, greaterThanOrEqualTo(89));
      expect(space.currentBillAmount, 238.0);

      // Service finished -> Dirty (waiting for cleanup)
      space.status = SpaceStatus.dirty;
      expect(space.status, SpaceStatus.dirty);
      expect(space.status.label, '待清台复位');

      // Reset to idle
      space.status = SpaceStatus.idle;
      space.currentSessionId = null;
      space.currentCustomerName = null;
      space.serviceStartTime = null;
      expect(space.status, SpaceStatus.idle);
      expect(space.servedMinutes, 0);
    });
  });
}
