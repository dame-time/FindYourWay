import 'package:find_your_way/data/map_config.dart';
import 'package:flutter/material.dart';

class MapData with ChangeNotifier {
  MapConfig? _mapConfig;

  MapConfig? get mapConfig => _mapConfig;

  void setMapConfig(MapConfig mapConfig) {
    _mapConfig = mapConfig;
    notifyListeners();
  }
}
