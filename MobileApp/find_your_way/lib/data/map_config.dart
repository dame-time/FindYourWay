class MapConfig {
  final String owner;
  final String mapConfig;
  final double dbp;

  MapConfig({required this.owner, required this.mapConfig, required this.dbp});

  factory MapConfig.fromJson(Map<String, dynamic> json) {
    String tmp = json['DBP'] as String;
    return MapConfig(
      owner: json['owner'] as String,
      mapConfig: json['mapConfig'] as String,
      dbp: double.parse(tmp),
    );
  }
}
