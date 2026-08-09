import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive {
                      
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

                         
  static const double sidebarExpanded = 256;
  static const double sidebarCollapsed = 72;

  static ScreenType screenType(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileMax) return ScreenType.mobile;
    if (w < tabletMax) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      screenType(context) == ScreenType.mobile;

  static bool isTabletOrDesktop(BuildContext context) => !isMobile(context);

  static bool isDesktop(BuildContext context) =>
      screenType(context) == ScreenType.desktop;

  static bool isAndroidMobile(BuildContext context) =>
      isMobile(context) &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  static bool usesSideNavigation(BuildContext context) =>
      isTabletOrDesktop(context);

                                   
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (screenType(context)) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  static double contentMaxWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 760, desktop: 960);

  static double horizontalPadding(BuildContext context) =>
      value<double>(context, mobile: 24, tablet: 32, desktop: 48);

  static int gridColumns(BuildContext context) =>
      value<int>(context, mobile: 2, tablet: 3, desktop: 4);

                                                                  
  static double bottomListPadding(BuildContext context) =>
      isMobile(context) ? MediaQuery.viewPaddingOf(context).bottom + 104 : 32;

                                             
                                                                  
                                                       
  static double metricTileWidth(double available, {int minCols = 2}) {
    const spacing = 12.0;
    int cols;
    if (available > 600) {
      cols = 4;
    } else if (available > 400) {
      cols = 3;
    } else {
      cols = minCols;
    }
    return (available - spacing * (cols - 1)) / cols;
  }
}

                                                   
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ContentContainer({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.contentMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}
