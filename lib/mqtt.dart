import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';
import 'dart:async';

class MQTTClientWrapper {
  final MqttServerClient client;
  final String topic;
  bool isConnected = false;
  bool isSubscribed = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 7);
  Function? showAlert;

  MQTTClientWrapper(String server, String topic, int port)
      : client = MqttServerClient(server, ''),
        topic = topic {
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
  }

  Future<void> connect() async {
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('Client exception: $e');
      client.disconnect();
    }
    on SocketException catch (e) {
      print('Socket exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      _reconnectAttempts = 0;
    } else {
      client.disconnect();
      _autoReconnect();
    }
  }


  void _autoReconnect() async {
    if (!isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print('Attempting to reconnect... (attempt $_reconnectAttempts)');
      connect();
      await Future.delayed(_reconnectDelay);
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached. Giving up.');
      if (showAlert != null) {
        showAlert!();
      }
    }
  }

  void onConnected() {
    print('Connected');
    isConnected = true;
  }

  void onDisconnected() {
    print('Disconnected');
    isConnected = false;
    isSubscribed = false;
    _autoReconnect();
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
    isSubscribed = true;
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void subscribe(void Function(String) messageHandler) {
    if (isConnected) {
      client.subscribe(topic, MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        messageHandler(pt);
      });
    }
  }

  void unsubscribe() {
    if (isConnected) {
      client.unsubscribe(topic);
      isSubscribed = false;
    }
  }

  void toggleSubscription(void Function(String) messageHandler) {
    if (isSubscribed) {
      unsubscribe();
    } else {
      subscribe(messageHandler);
    }
  }
}

