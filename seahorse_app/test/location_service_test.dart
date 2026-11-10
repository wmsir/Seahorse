import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/services/location_service.dart';

void main() {
  group('LocationService Automated Distance & Geofence Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('1. Distance between identical coordinates must be 0 meters', () {
      final dist = locationService.calculateDistanceMeters(
        34.265500, 108.953400,
        34.265500, 108.953400,
      );
      expect(dist, 0.0);
    });

    test('2. Distance between known landmarks (e.g. Xi\'an Bell Tower to Giant Wild Goose Pagoda ~4.5km)', () {
      // Bell Tower: 34.2595, 108.9470
      // Giant Wild Goose Pagoda: 34.2185, 108.9641
      final dist = locationService.calculateDistanceMeters(
        34.2595, 108.9470,
        34.2185, 108.9641,
      );
      // Distance is approximately 4,800 - 5,100 meters
      expect(dist, greaterThan(4500));
      expect(dist, lessThan(5500));
    });

    test('3. Allowed punch-in radius verification (500m standard)', () {
      locationService.allowedRadiusMeters = 500.0;

      // Within range
      expect(locationService.isWithinAllowedRadius(50.0), isTrue);
      expect(locationService.isWithinAllowedRadius(300.0), isTrue);
      expect(locationService.isWithinAllowedRadius(500.0), isTrue);

      // Out of range
      expect(locationService.isWithinAllowedRadius(501.0), isFalse);
      expect(locationService.isWithinAllowedRadius(1250.0), isFalse);
    });

    test('4. formatDistance formatting output', () {
      expect(locationService.formatDistance(45.2), '45 米');
      expect(locationService.formatDistance(350.0), '350 米');
      expect(locationService.formatDistance(1250.0), '1.25 公里');
      expect(locationService.formatDistance(5000.0), '5.00 公里');
    });

    test('5. SourceMode switching updates sourceMode property', () {
      locationService.setSourceMode(LocationSourceMode.simulationInStore);
      expect(locationService.sourceMode, LocationSourceMode.simulationInStore);

      locationService.setSourceMode(LocationSourceMode.simulationOutStore);
      expect(locationService.sourceMode, LocationSourceMode.simulationOutStore);

      locationService.setSourceMode(LocationSourceMode.realDevice);
      expect(locationService.sourceMode, LocationSourceMode.realDevice);
    });
  });
}
