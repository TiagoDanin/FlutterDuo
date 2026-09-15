import 'package:flutter/material.dart';

/// Says the tap leads nowhere — a tap that does nothing is worse than one that
/// admits it. Its own file because three places need it; it used to be two
/// identical copies plus a variant.
void showMockupNotice(BuildContext context, [String? what]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        what == null
            ? 'Este é um mockup: a ação não leva a nenhuma tela.'
            : 'Este é um mockup: $what não existe.',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
