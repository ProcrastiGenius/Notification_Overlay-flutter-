import 'dart:async';

import 'package:flutter/material.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:restart_app/restart_app.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MyApp());
}

final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
final ValueNotifier<String> overlayPosition = ValueNotifier<String>('');

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
                  final vibcheck = await Vibration.hasVibrator();
                  if (vibcheck == true) {
                    Vibration.vibrate(pattern: [500, 500,500, 500]);
                  }
                  final permission = await OverlayPopUp.checkPermission();
                  if (permission) {
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
                        {'mssg': 'Hello from dart!'});
                  }
                },
                color: Colors.red[900],
                child: const Text('Send data',
                    style: TextStyle(color: Colors.white)),
              ),
              MaterialButton(
                onPressed: () async {
                  if (await OverlayPopUp.isActive()) {
                    await OverlayPopUp.updateOverlaySize(
                        width: 500, height: 500);
                  }
                },
                color: Colors.red[900],
                child: const Text('Update overlay size',
                    style: TextStyle(color: Colors.white)),
              ),
              MaterialButton(
                onPressed: () async {
                  if (await OverlayPopUp.isActive()) {
                    final position = await OverlayPopUp.getOverlayPosition();
                    overlayPosition.value = (position?['overlayPosition'] != null)
                        ? position!['overlayPosition'].toString()
                        : '';
                  }
                },
                color: Colors.red[900],
                child: const Text('Get overlay position',
                    style: TextStyle(color: Colors.white)),
              ),
              ValueListenableBuilder<String>(
                valueListenable: overlayPosition,
                builder: (context, value, child) {
                  return Text('Current position: $value');
                },
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
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

class OverlayWidget extends StatelessWidget {
  const OverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(4),
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
                        fontSize: 20),
                  ),
                )),
            Card(
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                ),
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                            ),
                            Padding(
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
                                color: Colors.white70,
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
                          Icon(
                            Icons.more_vert_sharp,
                            color: Colors.white70,
                            size: 15,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: Colors.white70,
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

                    // const SizedBox(
                    //   height: 8,
                    // ),
                    const Divider(
                      thickness: 0.5,
                    ),
                    // const SizedBox(
                    //   height: 8,
                    // ),
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
                            await OverlayPopUp.closeOverlay();
                            Restart.restartApp();
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (context) => const RidePage()),
                            // );
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
                    // const SizedBox(height: 10),
                    // FloatingActionButton(
                    //   shape: const CircleBorder(),
                    //   backgroundColor: Colors.red[900],
                    //   elevation: 12,
                    //   onPressed: () async {
                    //     await OverlayPopUp.closeOverlay();
                    //     Restart.restartApp();
                    //   },
                    //   child: const Text('X',
                    //       style: TextStyle(color: Colors.white, fontSize: 20)),
                    // ),
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
// @pragma("vm:entry-point")
// void overlayPopUp() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: OverlayWidget(),
//   ));
// }

// class OverlayWidget extends StatelessWidget {
//   const OverlayWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         padding: const EdgeInsets.all(15),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(
//               child: StreamBuilder(
//                 stream: OverlayPopUp.dataListener,
//                 initialData: null,
//                 builder: (BuildContext context, AsyncSnapshot snapshot) {
//                   return Text(
//                     snapshot.data?['mssg'] ?? '',
//                     style: const TextStyle(fontSize: 14),
//                     textAlign: TextAlign.center,
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 10),
//             FloatingActionButton(
//               shape: const CircleBorder(),
//               backgroundColor: Colors.red[900],
//               elevation: 12,
//               onPressed: () async {
//                 await OverlayPopUp.closeOverlay();
//                 Restart.restartApp();
//               },
//               child: const Text('X',
//                   style: TextStyle(color: Colors.white, fontSize: 20)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


