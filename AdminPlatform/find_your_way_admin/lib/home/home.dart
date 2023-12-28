import 'dart:convert';
import 'package:find_your_way_admin/login/login.dart';
import 'package:find_your_way_admin/map/map_settings.dart';
import 'package:find_your_way_admin/provider/user_data.dart';
import 'package:find_your_way_admin/tracker/tracker_management.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<String>> _createdBuildingsFuture;

  bool _isLoading = false;

  Future<List<String>> retrieveData(String owner) async {
    final response = await http.post(
      Uri.parse('https://find-your-way-admin.serveo.net/retrieve_data'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'owner': owner}),
    );

    if (response.statusCode == 200) {
      var message = jsonDecode(response.body)['msg'];
      return json.decode(message).cast<String>().toList();
    } else {
      throw Exception('Failed to retrieve data');
    }
  }

  Future<void> removeMap(String owner, String buildingID) async {
    try {
      setState(() {
        _isLoading = true; // Start loading
      });

      final response = await http.post(
        Uri.parse('https://find-your-way-admin.serveo.net/remove_map'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'buildingID': buildingID, 'owner': owner}),
      );

      if (response.statusCode == 200) {
        _refreshData();
        setState(() {}); // Trigger a rebuild
      } else {
        throw Exception('Failed to remove map');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    String owner = Provider.of<UserData>(context, listen: false).username ?? '';
    _createdBuildingsFuture = retrieveData(owner);
  }

  @override
  Widget build(BuildContext context) {
    String username = Provider.of<UserData>(context).username ?? 'User';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
        title: Text('Welcome, $username!'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshData();
          setState(() {});
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<String>>(
            future: _createdBuildingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.data!.isEmpty) {
                return const Center(
                    child:
                        Text('No map was found! Please create one first...'));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      TrackerManagement(
                                buildingID: snapshot.data![index],
                              ),
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
                        // TODO: Add in there a screen where we can link a map logger
                        // the map logger will log map temperature and humidity and also will have a sensor for movement
                        // the movement will be registered and will be sent to AWS and logged in a database
                        // then for each map if we have a registered device for the log we will show the logged data on request
                      },
                      child: ListTile(
                        title: Text(
                            snapshot.data![index]), // Replace with actual data
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          MapSettings(
                                        buildingID: snapshot.data![index],
                                      ),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.ease;

                                        var tween = Tween(
                                                begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        var offsetAnimation =
                                            animation.drive(tween);

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                removeMap(username, snapshot.data![index]);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
