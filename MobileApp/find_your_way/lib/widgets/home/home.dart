import 'dart:convert';

import 'package:find_your_way/drawers/home_menu.dart';
import 'package:find_your_way/widgets/building/building_login.dart';
import 'package:find_your_way/widgets/building/building_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  final ZoomDrawerController _drawerController = ZoomDrawerController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _drawerController,
      menuScreen: HomeMenu(
        zoomDrawerController: _drawerController,
      ),
      mainScreen: MainScreen(
        drawerController: _drawerController,
        searchController: _searchController,
      ),
      borderRadius: 24.0,
      showShadow: true,
      angle: -10.0,
      menuBackgroundColor: Theme.of(context).colorScheme.shadow,
      shadowLayer2Color: Theme.of(context).highlightColor.withOpacity(0.9),
      shadowLayer1Color:
          Theme.of(context).colorScheme.secondary.withOpacity(0.25),
      slideWidth: MediaQuery.of(context).size.width * 0.65,
      openCurve: Curves.fastOutSlowIn,
      closeCurve: Curves.bounceIn,
    );
  }
}

class MainScreen extends StatefulWidget {
  final ZoomDrawerController drawerController;
  final TextEditingController searchController;

  const MainScreen({
    Key? key,
    required this.drawerController,
    required this.searchController,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = false;

  Future<void> _findBuilding() async {
    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> requestData = {
      'buildingID': widget.searchController.text.trim(),
    };

    String lambdaUrl =
        'https://leikrr7edha4dijk6fzgxymjfe0qyyei.lambda-url.eu-west-2.on.aws/';
    var response = await http.post(
      Uri.parse(lambdaUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200 && response.body.contains("ACK")) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                BuildingLogin(
              buildingID: widget.searchController.text.trim(),
            ),
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

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to find building.\nID does not exist!'),
          duration: Duration(seconds: 3),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () => widget.drawerController.toggle!(),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    child: const Icon(
                      FontAwesomeIcons.userNinja,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                FontAwesomeIcons.house,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Find your building',
                  prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                  suffixIcon: IconButton(
                    icon: const Icon(FontAwesomeIcons.arrowRightToBracket),
                    onPressed: _isLoading ? null : _findBuilding,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const BuildingRegistration(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ));
                },
                child: Text(
                  "Don't have a registered building?\nStart now!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
