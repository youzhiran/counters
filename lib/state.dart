import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalState {
  final navigatorKey = GlobalKey<NavigatorState>();

  final filter = ImageFilter.blur(
    sigmaX: 5,
    sigmaY: 5,
    tileMode: TileMode.mirror,
  );

  Future<T?> showCommonDialog<T>({
    required Widget child,
    bool dismissible = true,
  }) async {
    return await showModal<T>(
      context: navigatorKey.currentState!.context,
      configuration: FadeScaleTransitionConfiguration(
        barrierColor: Colors.black38,
        barrierDismissible: dismissible,
      ),
      builder: (_) => child,
      filter: filter,
    );
  }

  Future<bool?> showMessage<bool>({
    required String title,
    required InlineSpan message,
    String? confirmText,
  }) async {
    return await showCommonDialog<bool>(
      child: Builder(
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                    children: [message],
                  ),
                  style: const TextStyle(
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(confirmText ?? '确认'),
              )
            ],
          );
        },
      ),
    );
  }


  openUrl(String url) async {
    final res = await showMessage(
      message: TextSpan(text: url),
      title: '外部链接',
      confirmText: '前往',
    );
    if (res != true) {
      return;
    }
    launchUrl(Uri.parse(url));
  }

}

final globalState = GlobalState();
