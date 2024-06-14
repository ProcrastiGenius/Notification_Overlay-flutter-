import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:notification_overlay/ride.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:restart_app/restart_app.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MyApp());
}

final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
final ValueNotifier<Size> overlaySize =
    ValueNotifier<Size>(const Size(860, double.infinity));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the overlay status when the app starts
    overlayStatus();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: const Text('Flutter overlay pop up'),
            backgroundColor: Colors.red[900]),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isActive,
                builder: (context, value, child) {
                  return Text('Is active: $value');
                },
              ),
              MaterialButton(
                onPressed: () async {
                  // final vibcheck = await Vibration.hasVibrator();
                  // if (vibcheck == true) {
                  //   Vibration.vibrate(pattern: [500, 500, 500, 500]);
                  // }
                  final permission = await OverlayPopUp.checkPermission();
                  if (permission) {
                    if (!await OverlayPopUp.isActive()) {
                      final result = await OverlayPopUp.showOverlay(
                        height: 860,
                        screenOrientation: ScreenOrientation.portrait,
                        closeWhenTapBackButton: true,
                        isDraggable: true,
                        // verticalAlignment: Gravity.verticalGravityMask,
                        // horizontalAlignment: Gravity.centerHorizontal,
                      );
                      isActive.value = result;
                    } else {
                      final result = await OverlayPopUp.closeOverlay();
                      isActive.value = (result == true) ? false : true;
                    }
                  } else {
                    await OverlayPopUp.requestPermission();
                  }
                },
                color: Colors.red[900],
                child: const Text('Show overlay',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 14),
              MaterialButton(
                onPressed: () async {
                  if (await OverlayPopUp.isActive()) {
                    await OverlayPopUp.sendToOverlay(
                        {'mssg': 'New Trip \nRequest'});
                  }
                },
                color: Colors.red[900],
                child: const Text('Send data',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> overlayStatus() async {
  isActive.value = await OverlayPopUp.isActive();
}

///
/// the name is required to be `overlayPopUp` and has `@pragma("vm:entry-point")`
///
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: OverlayWidget(size: size),
        );
      },
    );
  }
}

class OverlayWidget extends StatelessWidget {
  final Size size;

  const OverlayWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return size.width == 200 && size.height == 400
        ? smallOverlayContent()
        : largeOverlayContent();
  }

  Widget smallOverlayContent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(1.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SizedBox(
            //   child: StreamBuilder(
            //     stream: OverlayPopUp.dataListener,
            //     initialData: null,
            //     builder: (BuildContext context, AsyncSnapshot snapshot) {
            //       return Text(
            //         snapshot.data?['mssg'] ?? '',
            //         style: const TextStyle(fontSize: 14),
            //         textAlign: TextAlign.center,
            //       );
            //     },
            //   ),
            // ),
            const SizedBox(height: 10),
            FloatingActionButton(
              shape: const CircleBorder(),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              elevation: 4,
              onPressed: () async {
                if (await OverlayPopUp.isActive()) {
                  await OverlayPopUp.updateOverlaySize(height: 860);
                  overlaySize.value = const Size(860, 860);
                }
              },
              child: Image.network(
                  'https://oraride.com/images/oraride-logo-white.png'),
            ),
            // Add other widgets specific to the small overlay
          ],
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
          // mainAxisAlignment: MainAxisAlignment.center,
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
                        fontSize: 20),
                  ),
                )),
            Card(
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(255, 38, 38, 38),
                ),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              radius: 30,
                              child: Image.network(
                                  'https://oraride.com/images/oraride-logo-white.png'),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer', //let it be customer for privacy
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    'Data', //let it be customer for privacy
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                            onPressed: () async {
                              if (await OverlayPopUp.isActive()) {
                                await OverlayPopUp.updateOverlaySize(
                                    width: 200, height: 400);
                                overlaySize.value = const Size(200, 400);
                              }
                              
                            },
                            icon: const Icon(
                              Icons.close_fullscreen,
                              color: Colors.white70,
                              size: 20,
                            )),
                        IconButton(
                            onPressed: () async {
                              await OverlayPopUp.closeOverlay();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Color.fromARGB(179, 255, 0, 0),
                                size: 18,
                              ),
                              Text(
                                'Data', //let it be customer for privacy
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.more_vert_sharp,
                            color: Colors.white70,
                            size: 18,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 1,
                              ),
                              Icon(
                                Icons.fiber_manual_record,
                                color: Color.fromARGB(179, 68, 118, 255),
                                size: 15,
                              ),
                              Text(
                                'Data', //let it be customer for privacy
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Text(
                          'Trip Status: ', //let it be customer for privacy
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.green),
                          child: const Text(
                            'STATUS', //let it be customer for privacy
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      thickness: 0.5,
                    ),
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
                                )),
                            IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.message,
                                  color: Colors.white70,
                                )),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            //  Restart.restartApp();
                            Get.to(const RidePage());
                            // await OverlayPopUp.closeOverlay();
                           
                          },
                          child: const Text(
                            'OPEN APP', //let it be customer for privacy
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        )
                      ],
                    )
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
