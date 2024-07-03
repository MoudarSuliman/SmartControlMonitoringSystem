import 'package:controlapp/wifiDiscovery.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:controlapp/mainPage.dart';

class DevicesListPage extends StatefulWidget {
  @override
  _DevicesListPageState createState() => _DevicesListPageState();
}
enum RegisterDeviceResult { success, deviceNotFound, alreadyRegistered }

class _DevicesListPageState extends State<DevicesListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RegisterDeviceResult transactionResult = RegisterDeviceResult.success;
 
Future<RegisterDeviceResult> registerDevice(String deviceId, String deviceName) async {
  String? userId = _auth.currentUser?.uid;
  var deviceDoc = await _firestore.collection('allDevices').doc(deviceId).get();
  if (!deviceDoc.exists) {
    return RegisterDeviceResult.deviceNotFound;
  }
  if (userId != null && deviceId.isNotEmpty) {
    DocumentReference userDevicesDoc = _firestore.collection('userDevices').doc(userId);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDevicesDoc);
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>? ?? {};
      List<dynamic> devices = data.containsKey('devices') ? data['devices'] as List : [];
      if (devices.any((device) => device['id'] == deviceId)) {

        transactionResult = RegisterDeviceResult.alreadyRegistered;
        return; 
      }
      devices.add({ 'id': deviceId, 'name': deviceName });
      if (!snapshot.exists) {
        transaction.set(userDevicesDoc, {'devices': devices});
      } else {
        transaction.update(userDevicesDoc, {'devices': devices});
      }
    });
    return transactionResult;
  }   
  return RegisterDeviceResult.deviceNotFound;
}

Future<bool> removeDevice(String deviceId) async {
  String? userId = _auth.currentUser?.uid;
  if (userId == null || deviceId.isEmpty) {
    return false;
  }

  DocumentReference userDevicesDoc = _firestore.collection('userDevices').doc(userId);

  return _firestore.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(userDevicesDoc);
    if (!snapshot.exists) {
      return false; 
    }

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>? ?? {};
    List<dynamic> devices = data['devices'] as List? ?? [];

    int indexToRemove = devices.indexWhere((device) => device['id'] == deviceId);
    if (indexToRemove == -1) {
      return false; 
    }

    devices.removeAt(indexToRemove); 
    transaction.update(userDevicesDoc, {'devices': devices}); 

    return true; 
  }).then((result) => result as bool).catchError((error) {
    print("Failed to remove device: $error");
    return false;
  });
}


  
  void showAddDeviceDialog() {
    TextEditingController deviceIdController = TextEditingController();
    TextEditingController deviceNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deviceIdController,
                decoration: InputDecoration(hintText: "Enter Device ID"),
              ),
              TextField(
                controller: deviceNameController,
                decoration: InputDecoration(hintText: "Enter Device Name"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                RegisterDeviceResult result = await registerDevice(deviceIdController.text.trim(), deviceNameController.text.trim());
                Navigator.of(context).pop();
                if (result == RegisterDeviceResult.alreadyRegistered) {
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Device is already registered")));
                }
                else if (result == RegisterDeviceResult.deviceNotFound) {
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Device ID does not exist")));
                }
                debugPrint("Result: $result");
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Devices'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage()),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('userDevices')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return Center(child: Text('No devices found.'));
          }

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> devices = data['devices'] ?? [];

          if (devices.isEmpty) {
            return Center(child: Text('No devices found.'));
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.devices),
                  title: Text(devices[index]['name'], style: TextStyle(fontSize: 20)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          bool removed = await removeDevice(devices[index]['id']);
                          if (removed) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Device successfully removed")));
                            setState(() {}); // Refresh the state to reflect the removal
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to remove device")));
                          }
                        },
                      ),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                  onTap: () {
  
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DataPage()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddDeviceDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Device',
      ),
    );
  }
}
