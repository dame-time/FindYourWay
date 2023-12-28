import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Color openNodeColor = Colors.green;
  Color closedNodeColor = Colors.red;
  Color joinNodeColor = Colors.blue;
  Color beaconNodeColor = Colors.orange;
  Color privateNodeColor = Colors.purple;
  Color userNodeColor = Colors.yellow;
  Color selectedNodeColor = Colors.amber;
  Color pathNodeColor = Colors.cyan;

  void changeColor(Color color, String nodeType) {
    setState(() {
      switch (nodeType) {
        case 'open':
          openNodeColor = color;
          break;
        case 'closed':
          closedNodeColor = color;
          break;
        case 'join':
          joinNodeColor = color;
          break;
        case 'beacon':
          beaconNodeColor = color;
          break;
        case 'private':
          privateNodeColor = color;
          break;
        case 'user':
          userNodeColor = color;
          break;
        case 'selected':
          selectedNodeColor = color;
          break;
        case 'path':
          pathNodeColor = color;
          break;
      }
    });
    // TODO: Persist the color changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Open Node Color'),
            trailing: Icon(Icons.circle, color: openNodeColor),
            onTap: () {
              pickColor(context, openNodeColor, 'open');
            },
          ),
          ListTile(
            title: const Text('Closed Node Color'),
            trailing: Icon(Icons.circle, color: closedNodeColor),
            onTap: () {
              pickColor(context, closedNodeColor, 'closed');
            },
          ),
          ListTile(
            title: const Text('Join Node Color'),
            trailing: Icon(Icons.circle, color: joinNodeColor),
            onTap: () {
              pickColor(context, joinNodeColor, 'join');
            },
          ),
          ListTile(
            title: const Text('Beacon Node Color'),
            trailing: Icon(Icons.circle, color: beaconNodeColor),
            onTap: () {
              pickColor(context, beaconNodeColor, 'beacon');
            },
          ),
          ListTile(
            title: const Text('Private Node Color'),
            trailing: Icon(Icons.circle, color: privateNodeColor),
            onTap: () {
              pickColor(context, privateNodeColor, 'private');
            },
          ),
          ListTile(
            title: const Text('User Node Color'),
            trailing: Icon(Icons.circle, color: userNodeColor),
            onTap: () {
              pickColor(context, userNodeColor, 'user');
            },
          ),
          ListTile(
            title: const Text('Selected Node Color'),
            trailing: Icon(Icons.circle, color: selectedNodeColor),
            onTap: () {
              pickColor(context, selectedNodeColor, 'selected');
            },
          ),
          ListTile(
            title: const Text('Path Node Color'),
            trailing: Icon(Icons.circle, color: pathNodeColor),
            onTap: () {
              pickColor(context, pathNodeColor, 'path');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).highlightColor,
                minimumSize:
                    const Size.fromHeight(50), // Fixed height for the button
              ),
              onPressed: saveSettings,
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  void saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('openNodeColor', openNodeColor.value);
    prefs.setInt('closedNodeColor', closedNodeColor.value);
    prefs.setInt('joinNodeColor', joinNodeColor.value);
    prefs.setInt('beaconNodeColor', beaconNodeColor.value);
    prefs.setInt('privateNodeColor', privateNodeColor.value);
    prefs.setInt('userNodeColor', userNodeColor.value);
    prefs.setInt('selectedNodeColor', selectedNodeColor.value);
    prefs.setInt('pathNodeColor', pathNodeColor.value);
  }

  void pickColor(BuildContext context, Color currentColor, String nodeType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) => changeColor(color, nodeType),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
