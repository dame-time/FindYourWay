import 'dart:io';
import 'package:find_your_way/provider/trilateration_data.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path_provider/path_provider.dart';

class MqttManager {
  final String server;
  final int port;
  final String clientIdentifier;
  final int numberOfUWBDevices;
  final TrilaterationData triangulationData;

  MqttServerClient? _client;

  MqttManager({
    required this.server,
    required this.port,
    required this.clientIdentifier,
    required this.numberOfUWBDevices,
    required this.triangulationData,
  });

  Future<bool> initializeMQTTClient() async {
    _client = MqttServerClient.withPort(server, clientIdentifier, port);

    // Set up secure connection
    final context = SecurityContext.defaultContext;

    // Load certificate files
    final certBytes = (await rootBundle.load(
            'assets/cert/7583935dc36fc25b1b78f13389d6ac7ea597f33f0b46bca1f20f0e6c8aca019a-certificate.pem.crt'))
        .buffer
        .asUint8List();
    final keyBytes = (await rootBundle.load(
            'assets/cert/7583935dc36fc25b1b78f13389d6ac7ea597f33f0b46bca1f20f0e6c8aca019a-private.pem.key'))
        .buffer
        .asUint8List();
    final rootCABytes = (await rootBundle.load('assets/cert/AmazonRootCA1.pem'))
        .buffer
        .asUint8List();

    // Write to temporary files
    final tempDir = await getTemporaryDirectory();
    final certFile = File('${tempDir.path}/certificate.pem.crt');
    final keyFile = File('${tempDir.path}/private.pem.key');
    final rootCAFile = File('${tempDir.path}/AmazonRootCA1.pem');

    await certFile.writeAsBytes(certBytes);
    await keyFile.writeAsBytes(keyBytes);
    await rootCAFile.writeAsBytes(rootCABytes);

    // Use these files in your SecurityContext
    context.useCertificateChain(certFile.path);
    context.usePrivateKey(keyFile.path);
    context.setTrustedCertificates(rootCAFile.path);

    _client!.secure = true;
    _client!.autoReconnect = true;
    _client!.resubscribeOnAutoReconnect = true;

    _client!.securityContext = context;
    _client!.onDisconnected = _onDisconnected;

    try {
      await _client!.connect();
    } catch (e) {
      // print('Error: $e');
      _client!.disconnect();
      return false;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      // print('MQTT Client connected');
      subscribeToTopic();
    } else {
      // print(
      //     'ERROR: MQTT Client connection failed - disconnecting, status is ${_client!.connectionStatus}');
      _client!.disconnect();
      return false;
    }

    return true;
  }

  void subscribeToTopic() {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      for (int i = 0; i < numberOfUWBDevices; i++) {
        triangulationData.addDevice("esp32/data/LoRa_DAME_00${i + 1}");
      }

      _client!.subscribe("esp32/data/#", MqttQos.atLeastOnce);

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);

        _handlePayload(payload, c[0].topic);
      });
    }
  }

  void _handlePayload(String payload, String topic) {
    if (payload.contains("DIST:")) {
      payload = payload.substring(5).trim();
      triangulationData.addDistance(topic, double.parse(payload));
    }
  }

  void _onDisconnected() {
    // print('MQTT Client disconnected');
  }

  void disconnect() {
    triangulationData.clear();
    _client?.disconnect();
  }
}
