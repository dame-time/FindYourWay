import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:find_your_way/provider/user_data.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class MapCreation extends StatefulWidget {
  const MapCreation({Key? key}) : super(key: key);

  @override
  State<MapCreation> createState() => _MapCreationState();
}

class _MapCreationState extends State<MapCreation> {
  final TextEditingController _mapConfigController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapConfigController.addListener(_onTextChanged);
    _distanceController.addListener(_onTextChanged);
    _fileNameController.addListener(_onTextChanged);
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

  void _saveFile() async {
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

    Map<String, dynamic> data = {
      "mapConfig": mapConfig,
      "DBP": distanceBetweenPoints,
      "owner": owner
    };

    String jsonString = jsonEncode(data);

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return;
    }

    String fileName = '${_fileNameController.text.trim()}.json';
    String filePath = '$selectedDirectory/$fileName';
    File file = File(filePath);

    await file.writeAsString(jsonString);

    if (!mounted) return;

    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    bool isSaveButtonDisabled = _mapConfigController.text.trim().isEmpty ||
        _distanceController.text.trim().isEmpty ||
        _fileNameController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Map Configuration'),
      ),
      body: SingleChildScrollView(
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
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: ElevatedButton(
                  onPressed: isSaveButtonDisabled ? null : _saveFile,
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
      ),
    );
  }
}
