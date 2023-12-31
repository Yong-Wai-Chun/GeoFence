import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:location/location.dart' as loca;
import 'package:geolocator/geolocator.dart';
//import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

//dasdaddaadas

void main() {
  runApp(MyApp());
}

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
  UserLocation? userLocation;
  Position? _currentLocation;
  //int regionRadius = 60;
  //double regionLatitude = 3.1069;
  //double regionLongitude = 101.4678;
  String regionStatus = '';
  String clockStatus = "Out";
  String ismock = "";
  var clockedLatitude;
  var clockedLongitude;
  List<RegionLocation> regions = [
    RegionLocation(3.1069, 101.4678, 60),
    RegionLocation(3.1095, 101.4602, 60),
    RegionLocation(3.0646, 101.4839, 100),
  ];

  Geolocator geolocator = Geolocator();
  StreamSubscription<Position>? positionStream;
  StreamSubscription<Position>? positionStream2;

  StreamController<UserLocation> _locationController =
      StreamController<UserLocation>();
  Stream<UserLocation> get locationStream => _locationController.stream;
  late LocationSettings locationSettings;

  @override
  void initState() {
    super.initState();
    locationPermission();
  }

  void locationPermission() async {
    var status = await Permission.location.status;

    loca.Location location = new loca.Location();
    var isServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isServiceEnabled) {
      //isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      isServiceEnabled = await location.requestService();
      if (!isServiceEnabled) {
        //isServiceEnabled = await location.requestService();
        ReasonDialog(context);
        //throw Exception("The Location service is disabled!");
      }
    } else {
      if (status.isDenied) {
        showAlertDialog(context);
      } else {
        _currentLocation = await Geolocator.getCurrentPosition().timeout(
          Duration(seconds: 10),
        );

        locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            forceLocationManager: true,
            intervalDuration: const Duration(seconds: 5),
            //(Optional) Set foreground notification config to keep the app alive
            //when going to the background
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationText:
                  "This app will continue to receive your location",
              notificationTitle: "Running in Background",
              enableWakeLock: true,
            ));
        Noti.initialize(flutterLocalNotificationsPlugin);
        LocationServices(locationSettings);
        //closeLocation();
      }
    }
  }

  showAlertDialog(context) => showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
              'SQL HRMS requires access to location to work\n\nTo get clocking location and more - SQL HRMS needs to access your location. \n\n In the App info page, please:\n\n* Tap "Permissions"\n* Tap "Location"\n * Select "Allow all the time" and return to app.'),
          actions: <CupertinoDialogAction>[
            // CupertinoDialogAction(
            //   onPressed: () => Navigator.of(context).pop(),
            //   child: const Text('Cancel'),
            // ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        ),
      );

  ReasonDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("GPS Service"),
      content: Text(
          "This application requires access to location\n\nPlease turn on your GPS to give access to your location"),
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

  void LocationServices(locationSettings) {
    setState(() {
      positionStream2 =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((location) {
        _locationController
            .add(UserLocation(location.latitude, location.longitude));
        print('B: ${location.latitude},${location.longitude}');

        setState(() {
          for (var reg in regions) {
            double distance = calculateDistance(location!.latitude,
                location!.longitude, reg.regionLatitude, reg.regionLongitude);

            if (_currentLocation!.isMocked == true) {
              ismock = "Yes";
              regionStatus = 'Please Enable Your Real Location.';
              Noti.showBigTextNotification(
                  title: "FAKE LOCATION DETECTED",
                  body: "Please Close Your Augmented Location",
                  fln: flutterLocalNotificationsPlugin);
            } else {
              ismock = "No";
              if (distance <= reg.regionRadius) {
                regionStatus = 'Inside the region';
                if (clockStatus == 'Out') {
                  Noti.showBigTextNotification(
                      title: "Clock In & Out Reminder",
                      body: "Remember to Clock In",
                      fln: flutterLocalNotificationsPlugin);
                }
                break;
              } else {
                regionStatus = 'Outside the region';
                if (clockStatus == 'In') {
                  Noti.showBigTextNotification(
                      title: "Clock In & Out Reminder",
                      body: "Remember to Clock Out",
                      fln: flutterLocalNotificationsPlugin);
                }
              }
            }
          }
        });
      });
    });
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

  Future<UserLocation> getCurrentLocation() async {
    try {
      loca.Location location = new loca.Location();
      var isServiceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!isServiceEnabled) {
        //isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        isServiceEnabled = await location.requestService();
        if (!isServiceEnabled) {
          //isServiceEnabled = await location.requestService();
          ReasonDialog(context);
          throw Exception("The Location service is disabled!");
        }
      }

      var isPermission = await Geolocator.checkPermission();
      if (isPermission == LocationPermission.denied ||
          isPermission == LocationPermission.deniedForever) {
        // request permission on the spot
        isPermission = await Geolocator.requestPermission();
      }
      if (isPermission == LocationPermission.denied ||
          isPermission == LocationPermission.deniedForever) {
        throw Exception("Location Permission requests has been denied!");
      }

      if (isServiceEnabled &&
          (isPermission == LocationPermission.always ||
              isPermission == LocationPermission.whileInUse)) {
        _currentLocation = await Geolocator.getCurrentPosition().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
                "Location information could not be obtained within the requested time.");
          },
        );

        //closeLocation();
        if (clockStatus == "Out") {
          userLocation = UserLocation(
              _currentLocation!.latitude, _currentLocation!.longitude);

          setState(() {
            clockedLatitude = userLocation!.latitude;
            clockedLongitude = userLocation!.longitude;
          });

          // close the stream first
          if (positionStream2 != null) {
            positionStream2!.cancel();
          }

          setState(() {
            locationSettings = AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 100,
                forceLocationManager: true,
                intervalDuration: const Duration(seconds: 10),
                //(Optional) Set foreground notification config to keep the app alive
                //when going to the background
                foregroundNotificationConfig:
                    const ForegroundNotificationConfig(
                  notificationText:
                      "This app will continue to receive your location",
                  notificationTitle: "Running in Background",
                  enableWakeLock: true,
                ));

            LocationServices(locationSettings);
          });

          setState(() {
            clockStatus = "In";
          });
        } else {
          if (positionStream2 != null) {
            positionStream2!.cancel();
          }

          setState(() {
            locationSettings = AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 100,
                forceLocationManager: true,
                intervalDuration: const Duration(seconds: 10),
                //(Optional) Set foreground notification config to keep the app alive
                //when going to the background
                foregroundNotificationConfig:
                    const ForegroundNotificationConfig(
                  notificationText:
                      "This app will continue to receive your location",
                  notificationTitle: "Running in Background",
                  enableWakeLock: true,
                ));

            LocationServices(locationSettings);
          });
          setState(() {
            clockedLatitude = null;
            clockedLongitude = null;
            clockStatus = "Out";
          });
        }

        return userLocation!;
      } else {
        throw Exception("Location Service requests has been denied!");
      }
    } on TimeoutException catch (_) {
      print(_);
      throw _;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Location and Region Tracking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MaterialButton(
                height: 60,
                minWidth: 200,
                child: const Text(
                  'CLOCK IN',
                  style: TextStyle(color: Colors.white),
                ),
                color: const Color(0xff1D1E22),
                onPressed: () {
                  //closeLocation();
                  getCurrentLocation();
                }),
            Text('Region Status: $regionStatus'),
            Text('Clocked In Latitude: ' + clockedLatitude.toString()),
            Text('Clocked In Longitude: ' + clockedLongitude.toString()),
            Text('Status: Clock $clockStatus'),
            Text('Mock Location Status: $ismock'),
          ],
        ),
      ),
    );
  }
}

class UserLocation {
  final double latitude;
  final double longitude;

  UserLocation(this.latitude, this.longitude);
}

class RegionLocation {
  final double regionLatitude;
  final double regionLongitude;
  final int regionRadius;

  RegionLocation(this.regionLatitude, this.regionLongitude, this.regionRadius);
}

class Noti {
  static Future initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize =
        new AndroidInitializationSettings('mipmap/ic_launcher');
    //var iOSInitialize = IOSInitializationSettings();
    var initializationsSettings = new InitializationSettings(
        android: androidInitialize); //, iOS: iOSInitialize);
    await flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  }

  static Future showBigTextNotification(
      {var id = 0,
      required String title,
      required String body,
      var payload,
      required FlutterLocalNotificationsPlugin fln}) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'clock_reminder1',
      'channel_name',
      playSound: true,
      //sound: RawResourceAndroidNotificationSound('notification'),
      importance: Importance.max,
      priority: Priority.high,
    );

    var not = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      //iOS: IOSNotificationDetails());
    );
    await fln.show(0, title, body, not);
  }
}
