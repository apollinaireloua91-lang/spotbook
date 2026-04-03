import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transition fade + slide de droite — navigation standard entre écrans.
class FadeSlideTransitionPage<T> extends CustomTransitionPage<T> {
  FadeSlideTransitionPage({
    required super.child,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final enterVal =
                Curves.easeOutCubic.transform(animation.value);
            return Opacity(
              opacity: enterVal.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(
                  (1.0 - enterVal) * MediaQuery.sizeOf(context).width * 0.08,
                  0,
                ),
                child: child,
              ),
            );
          },
        );
}

/// Transition scale depuis le centre — ouverture de sheets / modals.
class ScaleRotateTransitionPage<T> extends CustomTransitionPage<T> {
  ScaleRotateTransitionPage({
    required super.child,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final enterVal =
                Curves.easeOutBack.transform(animation.value);
            return Opacity(
              opacity: enterVal.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.92 + enterVal * 0.08,
                child: child,
              ),
            );
          },
        );
}

/// Transition 3D profondeur — la page sortante recule en Z et fade,
/// la nouvelle slide depuis la droite avec légère rotation Y.
///
/// Utilisée pour les changements d'onglets dans les ShellRoutes.
class DepthTransitionPage<T> extends CustomTransitionPage<T> {
  DepthTransitionPage({
    required super.child,
    super.key,
  }) : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final screenWidth = MediaQuery.sizeOf(context).width;

            // Page entrante : slide de droite + légère rotation Y
            final enterVal =
                Curves.easeOutCubic.transform(animation.value);
            final slideX = (1.0 - enterVal) * screenWidth * 0.3;
            final rotY = (1.0 - enterVal) * 0.02;

            // Page sortante (poussée par une nouvelle page) : recule + fade
            final exitVal =
                Curves.easeInCubic.transform(secondaryAnimation.value);
            final scale = 1.0 - (exitVal * 0.06);
            final fadeOut = 1.0 - (exitVal * 0.4);

            return Opacity(
              opacity: (enterVal * fadeOut).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(-rotY),
                  child: Transform.translate(
                    offset: Offset(slideX, 0),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
