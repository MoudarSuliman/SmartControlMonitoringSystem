import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LightPage extends StatefulWidget {
  @override
  _LightPageState createState() => _LightPageState();
}

class _LightPageState extends State<LightPage> {
  bool isLightOn = false;
  
  
  @override
  void initState() {
    super.initState();
    _getLightStatus(); // Initial fetch of the light's status
  }

  void _getLightStatus() async {
    final document = FirebaseFirestore.instance.collection('lights').doc('ednpr1YxRNjbseIofivM');
    document.snapshots().listen((snapshot) {
      setState(() {
        isLightOn = snapshot['On'] as bool; // Adjust field name as necessary
      });
    });
  }

  void _toggleLight(bool newValue) {
  final document = FirebaseFirestore.instance.collection('lights').doc('ednpr1YxRNjbseIofivM');
  document.update({"On": newValue}).then((_) {
    print("Light status updated");
    // Only update the local state after successful Firestore update to avoid race conditions
    setState(() {
      isLightOn = newValue;
    });
  }).catchError((error) {
    print("Failed to update light status: $error");
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Light Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
              color: isLightOn ? Colors.yellow : Colors.grey,
              size: 60,
            ),
            Switch(
              value: isLightOn,
              onChanged: (value) {
                _toggleLight(value);
              },
            ),
            Text(
              isLightOn ? 'The light is On' : 'The light is Off',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
