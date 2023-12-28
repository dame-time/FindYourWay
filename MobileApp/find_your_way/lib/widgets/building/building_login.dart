import 'package:find_your_way/data/map_config.dart';
import 'package:find_your_way/manager/mqtt_manager.dart';
import 'package:find_your_way/provider/map_data.dart';
import 'package:find_your_way/provider/trilateration_data.dart';
import 'package:find_your_way/provider/user_data.dart';
import 'package:find_your_way/widgets/map/surface_map.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class BuildingLogin extends StatefulWidget {
  final String buildingID;

  const BuildingLogin({Key? key, required this.buildingID}) : super(key: key);

  @override
  State<BuildingLogin> createState() => _BuildingLoginState();
}

class _BuildingLoginState extends State<BuildingLogin> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  MqttManager? mqttManager;

  bool isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.buildingID;
  }

  Future<void> login(
      BuildContext context, String username, String password) async {
    setState(() {
      isLoggingIn = true;
    });

    var buildingID = username;
    var buildingPassword = password;

    try {
      var response = await http.post(
        Uri.parse(
            'https://fduslodvp5tqmydflhpd7hiunq0zaies.lambda-url.eu-west-2.on.aws/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'buildingID': buildingID,
          'buildingPassword': buildingPassword,
        }),
      );

      if (response.statusCode == 200) {
        var message = response.body;
        var jsonResponse = json.decode(message);

        if (message.contains("ACK")) {
          MapConfig mapConfig = MapConfig.fromJson(jsonResponse['mapConfig']);

          if (!context.mounted) return;

          Provider.of<MapData>(context, listen: false).setMapConfig(mapConfig);

          _initMQTTManager().then((value) {
            if (value) {
              Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        SurfaceMap(
                      mqttManager: mqttManager!,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
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
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Something wen wrong!\nPlease, check the device connection to the network!'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        } else {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Provided data is wrong!\nPlease, try again!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred.\nPlease try again later.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false; // Stop loading
        });
      }
    }
  }

  Future<bool> _initMQTTManager() async {
    mqttManager ??= MqttManager(
      server: 'a3od7l38m9ccdd-ats.iot.eu-west-2.amazonaws.com',
      port: 8883,
      clientIdentifier:
          '${Provider.of<UserData>(context, listen: false).username!}_client',
      numberOfUWBDevices: 3, // TODO: add this field in the map config file
      triangulationData: Provider.of<TrilaterationData>(context, listen: false),
    );

    return await mqttManager!.initializeMQTTClient();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Building Login'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.lock_outline,
                  size: 90,
                  color: Colors.grey,
                ),
                const SizedBox(height: 48.0),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Building ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: isLoggingIn
                      ? null
                      : () {
                          login(context, usernameController.text,
                              passwordController.text);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).highlightColor,
                    minimumSize: const Size.fromHeight(
                        50), // Fixed height for the button
                  ),
                  child: isLoggingIn
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.tertiary),
                        )
                      : const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
