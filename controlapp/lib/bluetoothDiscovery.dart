import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class Discovery extends StatefulWidget {
  final bool start;

  Discovery({Key? key, this.start = true}) : super(key: key);

  @override
  _DiscoveryState createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results = [];
  bool isDiscovering= true;
  bool isBluetoothEnabled = false;
  @override
  void initState() {
    super.initState();
    if (widget.start) {
      _requestPermissions();
      _checkBluetoothState();
    }
  }

  void _checkBluetoothState() async {
    final bluetoothState = await FlutterBluetoothSerial.instance.state;
    setState(() {
      isBluetoothEnabled = bluetoothState == BluetoothState.STATE_ON;
    });
  }

  Future<void> _requestPermissions() async {
    final permissionStatus = await Permission.bluetoothScan.request();
    if (permissionStatus.isGranted) {
      _startDiscovery();
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Permission Required"),
          content: Text("Bluetooth scanning permission is required."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _startDiscovery() async {
  final bluetoothState = await FlutterBluetoothSerial.instance.state;
  if (bluetoothState == BluetoothState.STATE_ON) {
    setState(() {
      results.clear();
      isDiscovering = true;
      isBluetoothEnabled = true; 
    });
    _streamSubscription?.cancel();
    _streamSubscription = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((BluetoothDiscoveryResult result) {
      setState(() {
        if (result.device.name == "HC-05") { 
          final index = results.indexWhere(
              (element) => element.device.address == result.device.address);
          if (index >= 0) {
            results[index] = result;
          } else {
            results.add(result);
          }
        }
      });
    }, onError: (dynamic error) {
      debugPrint("Error during discovery: $error");
    }, onDone: () {
      debugPrint("Discovery finished.");
      setState(() {
        isDiscovering = false;
      });
    });
  } else {
    // Bluetooth is not on, show a message to the user
    setState(() {
      isBluetoothEnabled = false; // Update Bluetooth state
    });
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Bluetooth is off"),
        content: Text("Please turn on Bluetooth to discover devices."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}



  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isDiscovering ? 'Discovering devices...' : 'Discovered devices'),
        actions: <Widget>[
          isDiscovering
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _startDiscovery,
                ),
        ],
        backgroundColor: Colors.deepPurple,
        elevation: 4.0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _startDiscovery();
        },
        child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (BuildContext context, int index) {
            BluetoothDiscoveryResult result = results[index];
            return Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                leading: Icon(Icons.bluetooth, color: Colors.deepPurple),
                title: Text(result.device.name ?? "Unknown Device"),
                subtitle: Text(result.device.address),
            onTap: () {
              Navigator.pushNamed(context, '/pairingDevice', arguments: results[index].device);
            },
            ),
          );
        },
      ),
      ),
    );
  }
}
