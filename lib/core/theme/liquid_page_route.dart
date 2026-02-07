import 'package:flutter/material.dart';

class LiquidPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  LiquidPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Liquid "Fade + Scale" Transition
          var curve = Curves.easeOutQuart;
          var tween = Tween(
            begin: 0.95,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: ScaleTransition(scale: animation.drive(tween), child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}
