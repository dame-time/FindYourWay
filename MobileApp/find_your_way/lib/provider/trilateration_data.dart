import 'package:flutter/material.dart';

class TrilaterationData with ChangeNotifier {
  final Map<String, List<double>> _devicesDistance = {};

  final int maxSize = 3;

  Map<String, List<double>> get devicesDistance => _devicesDistance;

  bool addDevice(String deviceName) {
    if (devicesDistance.containsKey(deviceName)) return false;

    _devicesDistance[deviceName] = [];
    notifyListeners();

    return true;
  }

  bool addDistance(String deviceName, double distance) {
    if (!_devicesDistance.containsKey(deviceName)) return false;

    List<double> distances = _devicesDistance[deviceName]!;

    distances.add(distance);

    // TODO: Print here if a new distance is added, and where.
    // print("new distance added to $deviceName: $distance");

    // Remove the oldest element if the list exceeds maxSize
    if (distances.length > maxSize) {
      distances.removeAt(0);
    }

    notifyListeners();

    return true;
  }

  void clear() {
    _devicesDistance.clear();
    notifyListeners();
  }
}
