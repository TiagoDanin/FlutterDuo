import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Real full screen: no status bar, no navigation bar.
  //
  // A deliberate exception to `layout-chrome`, recorded in `STACK.md`: the
  // effect happens at the screen edges, and the system bars cover exactly that.
  // `immersiveSticky` returns them on a swipe, so nothing is unreachable.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Portrait lock, also an exception in `STACK.md`: movement is the primary
  // input, and auto-rotation would fight it mid-gesture.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HaloApp());
}
