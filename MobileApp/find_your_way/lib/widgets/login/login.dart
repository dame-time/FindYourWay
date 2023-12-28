import 'dart:typed_data';

import 'package:find_your_way/provider/user_data.dart';
import 'package:find_your_way/widgets/home/home.dart';
import 'package:find_your_way/widgets/signup/signup.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pointycastle/export.dart' hide Padding, State;
import 'package:asn1lib/asn1lib.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
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
        true,
        PublicKeyParameter<RSAPublicKey>(rsaPublicKey),
      );

    final inputBytes = Uint8List.fromList(input.codeUnits);
    final outputBytes = cipher.process(inputBytes);

    return base64.encode(outputBytes);
  }

  Future<void> login(
      BuildContext context, String username, String password) async {
    setState(() {
      isLoggingIn = true; // Start loading
    });

    var encryptedUsername = encryptWithPublicKey(username, publicKeyPEM);
    var encryptedPassword = encryptWithPublicKey(password, publicKeyPEM);

    try {
      var response = await http.post(
        Uri.parse(
            'https://xgvq7ndbh5da4vhvrjqa4cnwsm0tyqzt.lambda-url.eu-west-2.on.aws/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': encryptedUsername,
          'password': encryptedPassword,
        }),
      );

      if (response.statusCode == 200) {
        var message = response.body;
        if (message == "\"ACK\"") {
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
          Fluttertoast.showToast(msg: "Wrong password! Please, try again!");
        }
      } else {
        Fluttertoast.showToast(
            msg: "Please, provide a valid username and password!");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "An error occurred. Please try again later.");
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false; // Stop loading
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
                  Icons.lock_outline,
                  size: 90,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Welcome back\nyou\'ve been missed!',
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
                      : const Text('Sign In'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password'),
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
                                  const Signup(),
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
                  child: const Text('Not a member? Register now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
