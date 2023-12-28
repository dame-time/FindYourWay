class MapData {
  final String owner;
  final String mapConfig;
  final double dbp;

  MapData({required this.owner, required this.mapConfig, required this.dbp});

  factory MapData.fromJson(Map<String, dynamic> json) {
    String tmp = json['DBP'] as String;
    return MapData(
      owner: json['owner'] as String,
      mapConfig: json['mapConfig'] as String,
      dbp: double.parse(tmp),
    );
  }
}
