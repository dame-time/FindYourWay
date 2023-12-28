import 'dart:typed_data';

import 'package:find_your_way/provider/user_data.dart';
import 'package:find_your_way/widgets/home/home.dart';
import 'package:find_your_way/widgets/login/login.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pointycastle/export.dart' hide Padding, State;
import 'package:asn1lib/asn1lib.dart';
import 'package:provider/provider.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Controllers to capture text input
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  bool isLoggingIn = false;

  final publicKeyPEM =
      '''MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtzUCSjmt4BUVCrYrmguI
ISLW45xd3O1cgLbhhWGpuIZQ6dP9pNyEhoDDRp9J81dyM11dAj1qlQGWKCtYyqjR
BmsUMppLjhPT6zwmlFwyoaBr9yk9WsuCZKV7/Uv5qg3irzoyWHJdRNESLda2tVyi
b9oIsyrFHOkkjVBt6HOMs/4mRC71Tt4m5ReZxJWZhWn00cWc9YacaRiGA1TPggU1
JyqgHaVMRx7W0VTtlMk+djSrC+10WcZ338UWPTDbPOnHYwY5ElQbbpxUF/pF6Si5
uOz0n/ZKYqllVLawFFUNLvATORyqkWlzcMAd74FjedCGZF8lTp+sl3MCM0MYezhq
NwIDAQAB''';

  String encryptWithPublicKey(String input, String publicKeyPEM) {
    // Removing the PEM tags
    final publicKeyString = publicKeyPEM
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '');
    final publicKeyDer = base64.decode(publicKeyString);
    final asn1Parser = ASN1Parser(publicKeyDer);
    final ASN1Sequence topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final ASN1Object publicKeyBitString = topLevelSeq.elements[1];

    final publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes());
    final ASN1Sequence publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;

    final ASN1Integer modulus = publicKeySeq.elements[0] as ASN1Integer;
    final ASN1Integer exponent = publicKeySeq.elements[1] as ASN1Integer;

    final rsaPublicKey = RSAPublicKey(
      modulus.valueAsBigInteger,
      exponent.valueAsBigInteger,
    );

    final cipher = OAEPEncoding(RSAEngine())
      ..init(
        true, // true for encryption
        PublicKeyParameter<RSAPublicKey>(rsaPublicKey),
      );

    final inputBytes = Uint8List.fromList(input.codeUnits);
    final outputBytes = cipher.process(inputBytes);

    return base64.encode(outputBytes);
  }

  // Login function
  Future<void> signUp(
      BuildContext context, String username, String password) async {
    setState(() {
      isLoggingIn = true; // Start loading
    });

    var encryptedUsername =
        encryptWithPublicKey(username, publicKeyPEM); // Your PEM key
    var encryptedPassword =
        encryptWithPublicKey(password, publicKeyPEM); // Your PEM key

    // Send credentials to the server
    try {
      var response = await http.post(
        Uri.parse(
            'https://moty7hz7js4ptgtiuflce5cmjy0rhqdw.lambda-url.eu-west-2.on.aws/'), // Your Lambda URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': encryptedUsername,
          'password': encryptedPassword,
        }),
      );

      if (response.statusCode == 200) {
        var message = response.body;
        if (message.contains("successfully")) {
          if (!context.mounted) return;

          Provider.of<UserData>(context, listen: false)
              .setUserData(username, password);

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
          // Show toast for wrong password
          Fluttertoast.showToast(msg: "Please insert a valid password!");
        }
      } else {
        // Show toast for invalid input
        Fluttertoast.showToast(
            msg: "Please, provide a valid username and password!");
      }
    } catch (e) {
      // Handle any errors here
      Fluttertoast.showToast(msg: "An error occurred. Please try again later.");
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  FontAwesomeIcons.doorOpen,
                  size: 90,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Welcome to\nFind Your Way app!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24.0),
                ),
                const SizedBox(height: 48.0),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
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
                          signUp(context, usernameController.text,
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
                      : const Text('Sign Up'),
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
                    const Text('Or continue with'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/google_logo.png',
                        width: 24,
                      ),
                      onPressed: () {
                        // Handle Google Sign-In
                      },
                    ),
                    const SizedBox(width: 32.0),
                    IconButton(
                      icon: Image.asset(
                        'assets/facebook_logo.png',
                        width: 24,
                      ), // Replace with your asset image
                      onPressed: () {
                        // Handle Apple Sign-In
                      },
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const Login(),
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
                  },
                  child: const Text('Already a member? Log in now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
