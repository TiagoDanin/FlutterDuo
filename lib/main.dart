import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full screen. A `layout-chrome` exception recorded in `STACK.md`: the
  // effect lives at the screen edges and the bars cover exactly that.
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
