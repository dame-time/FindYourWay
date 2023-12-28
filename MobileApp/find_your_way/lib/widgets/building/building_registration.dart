import 'dart:convert';
import 'dart:typed_data';
import 'package:find_your_way/widgets/building/map_creation.dart';
import 'package:find_your_way/widgets/home/home.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class BuildingRegistration extends StatefulWidget {
  const BuildingRegistration({Key? key}) : super(key: key);

  @override
  State<BuildingRegistration> createState() => _RegisterBuildingState();
}

class _RegisterBuildingState extends State<BuildingRegistration> {
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _buildingPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _buildingNameController.addListener(_onTextChanged);
    _buildingPasswordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _buildingNameController.removeListener(_onTextChanged);
    _buildingPasswordController.removeListener(_onTextChanged);
    _buildingNameController.dispose();
    _buildingPasswordController.dispose();
    super.dispose();
  }

  bool isSubmitting = false;

  String? _fileName;
  Uint8List? _fileContent;

  Future<void> _pickConfigFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result?.files.single.extension != 'json') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid file.\nPlease choose a JSON map config file.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        _fileContent = result.files.single.bytes;
      });
    }
  }

  void _registerBuilding() async {
    setState(() {
      isSubmitting = true;
    });

    // Convert the Uint8List to a JSON object
    Map<String, dynamic>? mapConfigJson;
    if (_fileContent != null) {
      String fileContentStr = utf8.decode(_fileContent!);
      mapConfigJson = json.decode(fileContentStr);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register buildng.\nInvalid file content!'),
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        isSubmitting = false;
      });

      return;
    }

    Map<String, dynamic> requestData = {
      'buildingID': _buildingNameController.text,
      'buildingPassword': _buildingPasswordController.text,
      'mapConfig': mapConfigJson,
    };

    String lambdaUrl =
        'https://fgppctqtrrttmsvrise2cclcw40actjc.lambda-url.eu-west-2.on.aws/';
    var response = await http.post(
      Uri.parse(lambdaUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200) {
      print('Building registered successfully');

      if (!mounted) return;

      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Home(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ));
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register buildng.\nID already exists!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool areTxtControllersEmpty = _buildingNameController.text.trim().isEmpty ||
        _buildingPasswordController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.085),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.building,
                    size: 90,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: _buildingNameController,
                    decoration: const InputDecoration(
                      labelText: 'Building ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    obscureText: true,
                    controller: _buildingPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Building Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _pickConfigFile,
                    child:
                        Text(_fileName ?? 'Load Map Configuration File (JSON)'),
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
                      const Text('or'),
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const MapCreation(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                          ));
                    },
                    child: const Text('Create New Map Configuration File'),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  ElevatedButton(
                    onPressed: (isSubmitting || areTxtControllersEmpty)
                        ? null
                        : _registerBuilding,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Theme.of(context).highlightColor,
                      shadowColor: Theme.of(context).colorScheme.secondary,
                      elevation: 5,
                    ),
                    child: const Text('Register Building'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
