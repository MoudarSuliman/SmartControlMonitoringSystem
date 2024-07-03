import 'package:controlapp/devicesList.dart';
import 'package:controlapp/bluetoothDiscovery.dart'; 
import 'package:controlapp/wifiDiscovery.dart'; 
import 'package:flutter/material.dart';
import 'package:controlapp/pairingDevice.dart';
import 'package:controlapp/temperatureGraph.dart';
import 'package:controlapp/notificationService.dart';
import 'package:controlapp/lightPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "",
      appId: "",
      messagingSenderId: "",
      projectId: "",
      storageBucket: "",
    )
  ); // Initialize Firebase
  await NotificationService().initNotification();
  runApp(ControlApp());
}

class ControlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      routes: {'/' : (context) => user != null ? DevicesListPage() : MainPage(),
        '/pairingDevice': (context) => devicePairing(),
    '/temperatureGraph': (context) => TemperatureGraph(),
     '/lightPage': (context) => LightPage()},
    debugShowCheckedModeBanner: false,

    theme: ThemeData.dark(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    Discovery(), 
    LoginPage()
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi),
            label: 'Wi-Fi',
          ),
        ],
      ),
    );
  }
}
