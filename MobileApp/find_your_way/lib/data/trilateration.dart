import 'dart:math';

import 'package:find_your_way/data/kalman_filter.dart';
import 'package:find_your_way/data/position.dart';

class Trilateration {
  final List<Position> _beaconsPosition;
  final KalmanFilter _kalmanFilter;

  Trilateration({required List<Position> beaconsPosition})
      : _beaconsPosition = beaconsPosition,
        _kalmanFilter = KalmanFilter();

  Position? calculatePosition(
    double distanceToBeacon0,
    double distanceToBeacon1,
    double distanceToBeacon2,
  ) {
    final p1 = _beaconsPosition[0];
    final p2 = _beaconsPosition[1];
    final p3 = _beaconsPosition[2];

    // Using trilateration formula
    var A = 2.0 * p2.x - 2.0 * p1.x;
    var B = 2.0 * p2.y - 2.0 * p1.y;
    var C = pow(distanceToBeacon0, 2.0).toDouble() -
        pow(distanceToBeacon1, 2.0).toDouble() -
        pow(p1.x, 2.0).toDouble() +
        pow(p2.x, 2).toDouble() -
        pow(p1.y, 2).toDouble() +
        pow(p2.y, 2).toDouble();
    var D = 2.0 * p3.x - 2.0 * p2.x;
    var E = 2.0 * p3.y - 2.0 * p2.y;
    var F = pow(distanceToBeacon1, 2.0).toDouble() -
        pow(distanceToBeacon2, 2.0).toDouble() -
        pow(p2.x, 2.0).toDouble() +
        pow(p3.x, 2.0).toDouble() -
        pow(p2.y, 2.0).toDouble() +
        pow(p3.y, 2.0).toDouble();

    var x = (C * E - F * B) / (E * A - B * D);
    var y = (C * D - A * F) / (B * D - A * E);

    // Get the raw position from trilateration
    Position rawPosition = Position(x, y);

    // Update the Kalman Filter with the raw position and get the filtered position
    Position filteredPosition = _kalmanFilter.update(rawPosition);

    return filteredPosition;
  }
}
