import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

class devicePairing extends StatefulWidget {
  const devicePairing({super.key});

  @override
  State<devicePairing> createState() => _devicePairingState();
}

class _devicePairingState extends State<devicePairing> {
  bool bonded = false;
  BluetoothDevice? result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BluetoothDevice? device = ModalRoute.of(context)?.settings.arguments as BluetoothDevice?;
      if (device != null) {
        setState(() {
          result = device;
          bonded = device.isBonded;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(result!.name ?? "Unknown Device"),
        elevation: 5.0, 
        actions: [
          IconButton(
            icon: Icon(bonded ? Icons.link_off : Icons.link),
            onPressed: () async {
              await toggleBonding(result!);
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await toggleBonding(result!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bonded ? Colors.redAccent : Colors.green, 
                foregroundColor: Colors.white, 
                elevation: 3, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                minimumSize: Size(double.infinity, 50), 
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(bonded ? Icons.link_off : Icons.link),
                  SizedBox(width: 10),
                  Text(bonded ? "Unpair" : "Pair"),
                ],
              ),
            ),
            SizedBox(height: 20), 
            ElevatedButton(
              onPressed: () {
                navigateToGraphOrShowDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bonded ? Colors.red : Colors.green,
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), 
                ),
                elevation: 10, // Shadow depth
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                minimumSize: Size(double.infinity, 50), 
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart),
                  SizedBox(width: 10),
                  Text("Temperature Graph"),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                navigateToLightPageOrShowDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bonded ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline),
                  SizedBox(width: 10),
                  Text("Light Control"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleBonding(BluetoothDevice result) async {
    if (result.name != "HC-05") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Incorrect Device"),
            content: Text("You can only pair with the HC-05 device."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); 
                },
              ),
            ],
          );
        },
      );
      return;
    }

    if (bonded) {
      print('Unpairing ${result.name}...');
      bool unpaired = await FlutterBluetoothSerial.instance.removeDeviceBondWithAddress(result.address) ?? false;
      if (unpaired) {
        print('Unpairing ${result.name} succeeded.');
        setState(() {
          bonded = false; // Update the bonded status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unpaired successfully')),
        );
      } else {
        print('Unpairing ${result.name} failed.');
      }
    } else {
      print("Pairing with ${result.name}");
      bool bondedResult = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(result.address) ?? false;
      print('Bonding with ${result.name} has ${bondedResult ? 'succeeded' : 'failed'}.');
      setState(() {
        bonded = bondedResult; // Update the bonded status
      });
      if (bondedResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paired successfully')),
        );
      }
    }
  }

  void navigateToGraphOrShowDialog() {
    if (bonded) {
      
      Navigator.pushNamed(context, '/temperatureGraph');
    } else {

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Device Not Paired"),
            content: Text("Please pair the device before accessing the graph."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the alert dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  void navigateToLightPageOrShowDialog() {
    if (bonded) {
      Navigator.pushNamed(context, '/lightPage'); 
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Device Not Paired"),
            content: Text("Please pair the device before accessing the light page."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
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
}
