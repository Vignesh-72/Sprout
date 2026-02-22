import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class SproutBluetoothService {
  static final SproutBluetoothService _instance = SproutBluetoothService._internal();
  factory SproutBluetoothService() => _instance;
  SproutBluetoothService._internal();

  fbp.BluetoothDevice? connectedDevice;
  final List<String> targetDeviceNames = ["HC-05", "HM-10", "JDY-30", "JDY-31", "BT05"];

  final _connectionStateController = StreamController<fbp.BluetoothConnectionState>.broadcast();
  final _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<fbp.BluetoothConnectionState> get connectionStream => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get sensorStream => _sensorDataController.stream;

  Map<String, dynamic> lastKnownData = {'s': 0, 't': 0, 'h': 0, 'l': 0};

  // --- THE SCAN & CONNECT LOGIC ---
  Future<bool> scanAndConnect() async {
    if (connectedDevice != null) return true;

    Completer<bool> completer = Completer();
    bool deviceFound = false;

    try {
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      return false;
    }

    var subscription = fbp.FlutterBluePlus.scanResults.listen((results) async {
      for (fbp.ScanResult r in results) {
        if (targetDeviceNames.contains(r.device.platformName) && !deviceFound) {
          deviceFound = true;
          fbp.FlutterBluePlus.stopScan();
          
          bool success = await _connectWithRetry(r.device);
          if (!completer.isCompleted) completer.complete(success);
          break;
        }
      }
    });

    fbp.FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && !deviceFound && !completer.isCompleted) {
        completer.complete(false); 
      }
    });

    return completer.future;
  }

  Future<bool> _connectWithRetry(fbp.BluetoothDevice device) async {
    int attempts = 0;
    bool success = false;

    while (!success && attempts < 5) {
      attempts++;
      try {
        await device.connect(autoConnect: false).timeout(const Duration(seconds: 15));
        success = true;
      } catch (e) {
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    if (success) {
      connectedDevice = device;
      _discoverServices(device);
      
      device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == fbp.BluetoothConnectionState.disconnected) {
          connectedDevice = null;
        }
      });
      return true;
    }
    return false;
  }

  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    if (Platform.isAndroid) await device.requestMtu(512);
    try {
      List<fbp.BluetoothService> services = await device.discoverServices();
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
             await c.setNotifyValue(true);
             c.lastValueStream.listen((value) => _parseData(value));
          }
        }
      }
    } catch(e) { print("Discovery Error: $e"); }
  }

  void _parseData(List<int> rawBytes) {
    String rawString = utf8.decode(rawBytes, allowMalformed: true).trim();
    if (rawString.contains('{') && rawString.contains('}')) {
      try {
        int start = rawString.indexOf('{');
        int end = rawString.lastIndexOf('}');
        Map<String, dynamic> data = jsonDecode(rawString.substring(start, end + 1));
        lastKnownData = data;
        _sensorDataController.add(data);
      } catch (e) { }
    }
  }

  void disconnect() {
    connectedDevice?.disconnect();
    connectedDevice = null;
    _connectionStateController.add(fbp.BluetoothConnectionState.disconnected);
  }
}