import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:background_location/background_location.dart' as backLocation;
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:location/location.dart' as loca;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String locationUpdateText = '';
  String regionStatus = 'Outside the region';
  double regionLatitude = 0.0;
  double regionLongitude = 0.0;
  double currentLatitude = 0.0;
  double currentLongitude = 0.0;
  double regionRadius = 60.0; // in meters
  double _distance = 0;
  int _interval = 0;
  double? clockedLat = 0.0;
  double? clockedLon = 0.0;
  var locationStat = '';
  loca.Location location = loca.Location();

  var items = [
    'Walking',
    'Driving',
    'Running',
    'Motorcycle',
    'Customize',
  ];
  String dropdownvalue = 'Customize';

  TextEditingController regionLatController = TextEditingController();
  TextEditingController regionLonController = TextEditingController();
  TextEditingController _intervalController = TextEditingController();
  TextEditingController _distanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    locationPermission(0);
    initLocation();
  }

  Future<void> initLocation() async {
    backLocation.BackgroundLocation.getLocationUpdates((location) {
      setState(() {
        currentLatitude = location.latitude!;
        currentLongitude = location.longitude!;
        locationUpdateText =
            'Background location update: $currentLatitude, $currentLongitude';
        double distance = calculateDistance(
            currentLatitude, currentLongitude, regionLatitude, regionLongitude);
        if (distance <= regionRadius) {
          regionStatus = 'Inside the region';
        } else {
          regionStatus = 'Outside the region';
        }
      });
    });

    // Configure location settings
    backLocation.BackgroundLocation.startLocationService(
      distanceFilter: 10, // meters
    );
  }

  // Function to calculate the distance between two points using the haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    double phi1 = lat1 * pi / 180;
    double phi2 = lat2 * pi / 180;
    double deltaPhi = (lat2 - lat1) * pi / 180;
    double deltaLambda = (lon2 - lon1) * pi / 180;

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  showAlertDialogBox(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Location Permission"),
      content: Text('''
          SQL HRMS wants to use your location to remind you to clock on time, and more.
          
          When prompted, please tap "Allow in Settings", then select the "Allow all the time" option
        '''),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void updateActivity(String activity) {
    setState(() {
      dropdownvalue = activity;
      switch (dropdownvalue) {
        case 'Walking':
          _interval = 5000;
          _distance = 10;
          break;
        case 'Running':
          _interval = 3000;
          _distance = 20;
          break;
        case 'Driving':
          _interval = 10000;
          _distance = 50;
          break;
        case 'Motorcycle':
          _interval = 8000;
          _distance = 35;
          break;
        default:
          _interval = 5000;
          _distance = 10;
      }
    });
  }

  void locationPermission(int a) async {
    print('hello');
    var status = await Permission.location.status;
    if (status.isDenied) {
      print('Access Denied');
      showAlertDialog(context);
      //showAlertDialogBox(context);
      setState(() {
        locationStat = 'Permission Not Granted';
      });
    } else {
      locationToggle(a);
    }
  }

  void locationToggle(int b) async {
    loca.Location location = new loca.Location();
    bool _serviceEnabled;
    await backLocation.BackgroundLocation.startLocationService(
        distanceFilter: 20);
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      backLocation.BackgroundLocation.stopLocationService();
      if (!_serviceEnabled) {
        setState(() {
          locationStat = 'Location Denied';
        });
      } else {
        await backLocation.BackgroundLocation.setAndroidNotification(
          title: 'Background service is running',
          message: 'Background location in progress',
          icon: '@mipmap/ic_launcher',
        );
        loca.LocationData currentPosition = await location.getLocation();
        loca.LocationAccuracy desiredAccuracy = loca.LocationAccuracy.high;
        location.changeSettings(
          accuracy: desiredAccuracy,
          interval: _interval, // Location update interval in milliseconds
          distanceFilter:
              _distance, // Minimum distance to trigger location updates in meters
        );
        setState(() {
          locationStat = 'Location Enabled';
          if (b == 1) {
            clockedLat = currentPosition.latitude;
            clockedLon = currentPosition.longitude;
          }
        });
      } //);
    } else {
      await backLocation.BackgroundLocation.setAndroidNotification(
        title: 'Background service is running',
        message: 'Background location in progress',
        icon: '@mipmap/ic_launcher',
      );
      loca.LocationData currentPosition = await location.getLocation();
      loca.LocationAccuracy desiredAccuracy = loca.LocationAccuracy.high;
      location.changeSettings(
        accuracy: desiredAccuracy,
        interval: _interval, // Location update interval in milliseconds
        distanceFilter:
            _distance, // Minimum distance to trigger location updates in meters
      );
      setState(() {
        locationStat = 'Location Enabled';
        if (b == 1) {
          clockedLat = currentPosition.latitude;
          clockedLon = currentPosition.longitude;
        }
      });
    }
  }

  showAlertDialog(context) => showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Permission Denied'),
          content: const Text('Allow access to your location'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => openAppSettings(),
              child: const Text('Settings'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    print('run');
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Location and Region Tracking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(locationUpdateText),
            SizedBox(height: 20),
            TextField(
              controller: regionLatController,
              onChanged: (text) {
                setState(() {
                  regionLatitude = double.parse(text.replaceAll(',', ''));
                  double distance = calculateDistance(currentLatitude,
                      currentLongitude, regionLatitude, regionLongitude);
                  if (distance <= regionRadius) {
                    regionStatus = 'Inside the region';
                  } else {
                    regionStatus = 'Outside the region';
                  }
                });
              },
              decoration: InputDecoration(labelText: "Enter Region Latitude"),
              keyboardType:
                  TextInputType.numberWithOptions(signed: true, decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(
                    r'^-?\d*\.?\d*')), // Allow negative and decimal input
              ],
            ),
            TextField(
              controller: regionLonController,
              onChanged: (text) {
                setState(() {
                  regionLongitude = double.parse(text.replaceAll(',', ''));
                  double distance = calculateDistance(currentLatitude,
                      currentLongitude, regionLatitude, regionLongitude);
                  if (distance <= regionRadius) {
                    regionStatus = 'Inside the region';
                  } else {
                    regionStatus = 'Outside the region';
                  }
                });
              },
              decoration: InputDecoration(labelText: "Enter Region Longitude"),
              keyboardType:
                  TextInputType.numberWithOptions(signed: true, decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(
                    r'^-?\d*\.?\d*')), // Allow negative and decimal input
              ],
            ),
            SizedBox(height: 10),
            Text('Region Status: $regionStatus'),
            DropdownButton<String>(
              // Initial Value
              value: dropdownvalue,

              // Down Arrow Icon
              icon: const Icon(Icons.keyboard_arrow_down),

              // Array list of items
              items: items.map((String items) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items),
                );
              }).toList(),
              // After selecting the desired option,it will
              // change button value to selected value
              onChanged: (String? newValue) {
                setState(() {
                  dropdownvalue = newValue!;
                });
              },
            ),
            TextField(
              controller: _intervalController,
              decoration: InputDecoration(
                  hintText: 'Interval',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _intervalController.clear();
                    },
                    icon: const Icon(Icons.clear),
                  )),
            ),
            TextField(
              controller: _distanceController,
              decoration: InputDecoration(
                  hintText: 'Distance',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _distanceController.clear();
                    },
                    icon: const Icon(Icons.clear),
                  )),
            ),
            MaterialButton(
              onPressed: () {
                if (dropdownvalue == 'Customize') {
                  setState(() {
                    _interval =
                        int.parse(_intervalController.text.replaceAll(',', ''));
                    _distance = double.parse(
                        _distanceController.text.replaceAll(',', ''));
                  });
                }
              },
              color: Colors.blue,
              child: Text('Submit', style: TextStyle(color: Colors.white)),
            ),
            MaterialButton(
                height: 60,
                minWidth: 200,
                child: const Text(
                  'CLOCK IN',
                  style: TextStyle(color: Colors.white),
                ),
                color: const Color(0xff1D1E22),
                onPressed: () {
                  locationPermission(1);
                }),
            Text('Location Status:',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 28.0,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold)),
            Text(locationStat,
                style: TextStyle(
                    color: Colors.black, fontSize: 18.0, letterSpacing: 1.0)),
            Text('Latitude: ' + clockedLat.toString(),
                style: TextStyle(
                    color: Colors.black, fontSize: 18.0, letterSpacing: 1.0)),
            Text('Longitude: ' + clockedLon.toString(),
                style: TextStyle(
                    color: Colors.black, fontSize: 18.0, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}
