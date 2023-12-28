import 'dart:convert';
import 'dart:math';

import 'package:find_your_way_admin/data/map_data.dart';
import 'package:http/http.dart' as http;
import 'package:find_your_way_admin/provider/user_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapSettings extends StatefulWidget {
  final String buildingID;

  const MapSettings({Key? key, required this.buildingID}) : super(key: key);

  @override
  State<MapSettings> createState() => _MapSettingsState();
}

class _MapSettingsState extends State<MapSettings> {
  final TextEditingController _mapConfigController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  late Future<MapData> _mapData;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapConfigController.addListener(_onTextChanged);
    _distanceController.addListener(_onTextChanged);
    _fileNameController.addListener(_onTextChanged);

    _mapData = _getMapData();
    _mapData.then((mapData) {
      setState(() => _populateTextFields(mapData));
    });
  }

  Future<MapData> _getMapData() async {
    String owner = Provider.of<UserData>(context, listen: false).username ?? '';

    final response = await http.post(
      Uri.parse('https://find-your-way-admin.serveo.net/get_map'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'buildingID': widget.buildingID,
        'owner': owner,
      }),
    );

    if (response.statusCode == 200) {
      var message = jsonDecode(jsonDecode(response.body)['msg'])['mapConfig'];
      return MapData.fromJson(message);
    } else {
      throw Exception('Failed to retrieve data');
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _mapConfigController.removeListener(_onTextChanged);
    _distanceController.removeListener(_onTextChanged);
    _fileNameController.removeListener(_onTextChanged);
    _mapConfigController.dispose();
    _distanceController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _updateMapConfig() async {
    setState(() {
      _isLoading = true;
    });

    String mapConfig = _formatMapConfig(_mapConfigController.text);

    if (mapConfig.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Invalid map configuration. Please provide a valid one.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    String distanceBetweenPoints = _distanceController.text;
    String owner = Provider.of<UserData>(context, listen: false).username!;
    String fileName = _fileNameController.text.trim();

    Map<String, dynamic> data = {
      "mapConfig": mapConfig,
      "DBP": distanceBetweenPoints,
      "owner": owner,
      "buildingID": fileName
    };

    String jsonString = jsonEncode(data);

    try {
      var response = await http.post(
        Uri.parse(
            'https://find-your-way-admin.serveo.net/edit_map'), // Replace with your server endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonString,
      );

      if (!mounted) return;

      if (response.statusCode == 200 &&
          jsonDecode(response.body)['msg'] == "ACK") {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload data. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatMapConfig(String rawConfig) {
    List<String> rows = rawConfig
        .split('\n')
        .where((row) =>
            row.trim().isNotEmpty) // Filter out empty or whitespace-only lines
        .toList();

    if (rows.isEmpty) {
      return ''; // Return an empty string if all rows are empty
    }

    int maxLength = rows.map((r) => r.length).reduce(max);

    return rows.map((row) {
      // Pad shorter rows with '0' to make their length equal to maxLength
      String paddedRow = row.padRight(maxLength, '0');
      // Replace invalid characters with '0'
      return paddedRow.replaceAll(RegExp(r'[^0-3X]'), '0');
    }).join('\n');
  }

  void _populateTextFields(MapData mapData) {
    _mapConfigController.text = mapData.mapConfig;
    _distanceController.text = mapData.dbp.toString();
    _fileNameController.text = widget.buildingID;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Map Configuration'),
      ),
      body: FutureBuilder<MapData>(
        future: _mapData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _buildMapEditor(context);
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  SingleChildScrollView _buildMapEditor(BuildContext context) {
    bool isSaveButtonDisabled = _mapConfigController.text.trim().isEmpty ||
        _distanceController.text.trim().isEmpty ||
        _fileNameController.text.trim().isEmpty;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.map, // Or any other relevant icon
              size: 90,
              color: Colors.grey,
            ),
            const SizedBox(height: 24.0),
            TextField(
              controller: _fileNameController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    child: Divider(
                      color: Colors.grey.withOpacity(0.5),
                      height: 36,
                    ),
                  ),
                ),
                const Text('config'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 10.0),
                    child: Divider(
                      color: Colors.grey.withOpacity(0.5),
                      height: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _mapConfigController,
              decoration: const InputDecoration(
                labelText: 'Map Configuration',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null, // Allows for multiple lines
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _distanceController,
              decoration: const InputDecoration(
                labelText: 'Distance Between Points',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.4,
              ),
              child: ElevatedButton(
                onPressed: isSaveButtonDisabled || _isLoading
                    ? null
                    : _updateMapConfig,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).highlightColor,
                  shadowColor: Theme.of(context).colorScheme.secondary,
                  elevation: 5,
                ),
                child: const Text('Save Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
