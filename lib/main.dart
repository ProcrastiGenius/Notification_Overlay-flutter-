import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notification_overlay/ride.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:vibration/vibration.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:background_fetch/background_fetch.dart';

const HOME_SCREEN = '/HomeScreen';
const RIDEPAGE = '/Ridepage';
const NOT_FOUND = '/NotFound';
final FirebaseAuth auth = FirebaseAuth.instance;
Rx<TestData?> testdata = TestData().obs;
AnsiPen info = AnsiPen()..blue(bold: true);
AnsiPen success = AnsiPen()..green(bold: true);
AnsiPen warning = AnsiPen()..yellow(bold: true);
AnsiPen error = AnsiPen()..red(bold: true);

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // Do your work here...
  BackgroundFetch.finish(taskId);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

}

class TestData {
  String? id;
  String? message;
  String? location;

  TestData({this.id, this.message, this.location});

  TestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    message = json['message'];
    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['message'] = message;
    data['location'] = location;
    return data;
  }
}

Future<void> createNewDocument() async {
  final docRef = FirebaseFirestore.instance.collection('testdata').doc();
  await docRef.set({
    'id': docRef.id,
    'message': 'New trip',
    'location': 'Location name',
  });
}

final userCollection =
    FirebaseFirestore.instance.collection('testdata').withConverter<TestData>(
          fromFirestore: (snapshot, _) => TestData.fromJson(snapshot.data()!),
          toFirestore: (userData, _) => userData.toJson(),
        );

final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
final ValueNotifier<Size> overlaySize =
    ValueNotifier<Size>(const Size(860, double.infinity));
// final audioPlayer = AudioPlayer();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _lastDocId;
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  @override
  void initState() {
    super.initState();
    overlayStatus();
    listenForNewDocuments();
  }

  Future<void> listenForNewDocuments() async {
    FirebaseFirestore.instance
        .collection('testdata')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final newDoc = change.doc;
          final newDocId = newDoc.id;
          final testData =
              TestData.fromJson(newDoc.data() as Map<String, dynamic>);
          if (_lastDocId == newDocId) {
            return;
          } else {
            _lastDocId = newDocId;
            testdata.value = testData;
            showOverlayWithDocumentContents(testData);
            debugPrint(
                'New document added: ${testData.message}, ${testData.location}');
          }
        }
      }
    });
  }
 Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async {  // <-- Event handler
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      setState(() {
        _events.insert(0, new DateTime.now());
      });
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {  // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      unknownRoute: GetPage(name: NOT_FOUND, page: () => const RidePage()),
      initialRoute: HOME_SCREEN,
      getPages: [
        GetPage(
          name: HOME_SCREEN,
          page: () => const Home(),
        ),
        GetPage(name: RIDEPAGE, page: () => const RidePage())
      ],
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                'This is an example of Overlay Pop UP and overlay bubble.'),
            ValueListenableBuilder<bool>(
              valueListenable: isActive,
              builder: (context, value, child) {
                return Text('Is active: $value');
              },
            ),
            TextButton(
              onPressed: () {
                createNewDocument();
              },
              child: const Text('Generate RideRequest'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showOverlayWithDocumentContents(TestData testData) async {
  final vibcheck = await Vibration.hasVibrator();
  if (vibcheck == true) {
    Vibration.vibrate(pattern: [500, 500]);
  }
  // audioPlayer.play(AssetSource('sound.mp3'));

  if (!await OverlayPopUp.isActive()) {
    final result = await OverlayPopUp.showOverlay(
      height: 860,
      screenOrientation: ScreenOrientation.portrait,
      closeWhenTapBackButton: true,
      isDraggable: true,
    );
    isActive.value = result;
  } else {
    final result = await OverlayPopUp.closeOverlay();
    isActive.value = (result == true) ? false : true;
  }

  await OverlayPopUp.sendToOverlay({
    'message': testData.message,
    'location': testData.location,
  });
}

Future<void> overlayStatus() async {
  isActive.value = await OverlayPopUp.isActive();
}

@pragma("vm:entry-point")
void overlayPopUp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Size>(
      valueListenable: overlaySize,
      builder: (context, size, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          home: OverlayWidget(
            size: size,
            message: testdata.value?.message ?? '',
            location: testdata.value?.location ?? '',
          ),
        );
      },
    );
  }
}

class OverlayWidget extends StatelessWidget {
  final Size size;
  final String message;
  final String location;

  const OverlayWidget({
    super.key,
    required this.size,
    required this.message,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return size.width == 200 && size.height == 235
        ? smallOverlayContent()
        : largeOverlayContent();
  }

  Widget smallOverlayContent() {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: SafeArea(
        child: SizedBox(
          height: 235,
          width: 200,
          child: Center(
            child: Stack(
              children: [
                FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  elevation: 4,
                  onPressed: () async {
                    if (await OverlayPopUp.isActive()) {
                      await OverlayPopUp.updateOverlaySize(height: 865);
                      overlaySize.value = const Size(865, 860);
                    }
                  },
                  child: SizedBox(
                    width: 45,
                    child: ClipOval(
                      child: Image.network(
                        'https://avatars.githubusercontent.com/u/103909915?v=4',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: Colors.red,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          height: 1.5,
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget largeOverlayContent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(1.8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 5),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'OraRide',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Card(
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(255, 38, 38, 38),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 30,
                          child: ClipOval(
                            child: Image.network(
                              'https://avatars.githubusercontent.com/u/103909915?v=4',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Data',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            if (await OverlayPopUp.isActive()) {
                              await OverlayPopUp.updateOverlaySize(
                                width: 200,
                                height: 235,
                              );
                              overlaySize.value = const Size(200, 235);
                            }
                          },
                          icon: const Icon(
                            Icons.close_fullscreen,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await OverlayPopUp.closeOverlay();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color.fromARGB(179, 255, 0, 0),
                                size: 18,
                              ),
                              StreamBuilder(
                                stream: OverlayPopUp.dataListener,
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  return Text(
                                    snapshot.data?['location'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.more_vert_sharp,
                            color: Colors.white70,
                            size: 18,
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 1),
                              const Icon(
                                Icons.fiber_manual_record,
                                color: Color.fromARGB(179, 68, 118, 255),
                                size: 15,
                              ),
                              StreamBuilder(
                                stream: OverlayPopUp.dataListener,
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  return Text(
                                    snapshot.data?['message'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Trip Status:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        tripStatus('ENROUTE'),
                      ],
                    ),
                    const Divider(thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.call,
                                color: Colors.white70,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.message,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () async {},
                          child: const Text(
                            'ACCEPT',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Container tripStatus(String status) {
  if (status == 'WAITING') {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color.fromARGB(255, 91, 91, 91),
      ),
      child: const Text(
        'WAITING',
        style: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  } else if (status == 'ENROUTE') {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color.fromARGB(255, 255, 160, 45),
      ),
      child: const Text(
        'ENROUTE',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  } else if (status == 'COMPLETED') {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Colors.green,
      ),
      child: const Text(
        'COMPLETED',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  } else {
    return Container();
  }
}
