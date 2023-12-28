import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:find_your_way_admin/home/home.dart';
import 'package:find_your_way_admin/provider/user_data.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart' hide Padding;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
// import 'package:your_app_name/widgets/home/home.dart';

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
        Uri.parse('http://find-your-way-admin.serveo.net/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': encryptedUsername,
          'password': encryptedPassword,
        }),
      );

      var message = response.body;
      message = jsonDecode(message)['msg'];
      if (message == "ACK") {
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
    } catch (e) {
      print(e.toString());
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
                  'Welcome back!\nyou\'ve been missed...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24.0),
                ),
                const SizedBox(height: 48.0),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.2,
                  ),
                  child: TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.2,
                  ),
                  child: TextFormField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.4,
                  ),
                  child: ElevatedButton(
                    onPressed: isLoggingIn
                        ? null
                        : () {
                            login(context, usernameController.text,
                                passwordController.text);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).highlightColor,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: isLoggingIn
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
