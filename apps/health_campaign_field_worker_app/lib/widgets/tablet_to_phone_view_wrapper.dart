import 'package:flutter/material.dart';

class TabletToPhoneViewWrapper extends StatelessWidget {
  final Widget child;

  const TabletToPhoneViewWrapper({super.key, required this.child, phoneHeight});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Get the current MediaQueryData
        final originalMediaQuery = MediaQuery.of(context);
        final currentHeight = originalMediaQuery.size.height;
        final currentWidth = originalMediaQuery.size.width;

        final currentAspectRatio = currentWidth / currentHeight;

        const targetAspectRation = 0.55;

        final modifiedHeight = currentHeight;
        final modifiedWidth = currentAspectRatio < targetAspectRation
            ? currentWidth
            : (modifiedHeight * targetAspectRation);

        // Create a new MediaQueryData with phone-like dimensions
        final modifiedMediaQuery = originalMediaQuery.copyWith(
          size: Size(modifiedWidth, modifiedHeight),
          devicePixelRatio: originalMediaQuery.devicePixelRatio *
              (currentWidth / modifiedWidth),
        );

        // Provide the modified MediaQueryData to the child widget
        return MediaQuery(
          data: modifiedMediaQuery,
          child: Center(
            child: SizedBox(
              width: currentWidth,
              height: currentHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
