import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/bottom_nav_bar.dart';
import 'package:breath_state/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdaptiveScaffold extends StatelessWidget {
  final List<Widget> screens;

  const AdaptiveScaffold({super.key, required this.screens});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavBarProvider>(
      builder: (context, nav, _) {
        int idx = nav.getIndex();
        if (idx >= screens.length) {
          idx = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            nav.changeIndex(0);
          });
        }
        final type = Responsive.screenType(context);
        final useSideNavigation = Responsive.usesSideNavigation(context);

        if (Responsive.isAndroidMobile(context)) {
          return _AndroidMobileScaffold(
            screens: screens,
            currentIndex: idx,
            onIndexChanged: nav.changeIndex,
          );
        }

        if (useSideNavigation) {
          final expanded = type == ScreenType.desktop;
          return Scaffold(
            body: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Row(
                children: [
                  AppSidebar(
                    expanded: expanded,
                    currentIndex: idx,
                    onIndexChanged: (i) => nav.changeIndex(i),
                  ),
                  Expanded(
                    child: FadeIndexedStack(
                      index: idx,
                      children: screens,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          body: FadeIndexedStack(
            index: idx,
            children: screens,
          ),
          bottomNavigationBar: const BottomNavBar(),
        );
      },
    );
  }
}

class _AndroidMobileScaffold extends StatefulWidget {
  final List<Widget> screens;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _AndroidMobileScaffold({
    required this.screens,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  State<_AndroidMobileScaffold> createState() => _AndroidMobileScaffoldState();
}

class _AndroidMobileScaffoldState extends State<_AndroidMobileScaffold> {
  static const _topChromeHeight = 58.0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  double _horizontalDragDistance = 0;

  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDragDistance = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.primaryDelta ?? 0;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final hasEnoughDistance = _horizontalDragDistance.abs() >= 72;
    final hasEnoughVelocity = velocity.abs() >= 420;
    if (!hasEnoughDistance && !hasEnoughVelocity) return;

    final swipeDirection =
        hasEnoughVelocity ? velocity : _horizontalDragDistance;
    final nextIndex =
        swipeDirection < 0 ? widget.currentIndex + 1 : widget.currentIndex - 1;

    if (nextIndex < 0 || nextIndex >= widget.screens.length) return;
    widget.onIndexChanged(nextIndex);
  }

  void _changeIndex(int index) {
    if (index == widget.currentIndex) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    widget.onIndexChanged(index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    final adjustedMediaQuery = mediaQuery.copyWith(
      padding: safePadding.copyWith(top: safePadding.top + _topChromeHeight),
    );

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 64,
      drawerScrimColor: Colors.black.withValues(alpha: 0.34),
      drawer: Drawer(
        width: Responsive.sidebarExpanded,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        child: AppSidebar(
          expanded: true,
          currentIndex: widget.currentIndex,
          onIndexChanged: _changeIndex,
        ),
      ),
      body: Stack(
        children: [
          MediaQuery(
            data: adjustedMediaQuery,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _handleHorizontalDragStart,
              onHorizontalDragUpdate: _handleHorizontalDragUpdate,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              child: FadeIndexedStack(
                index: widget.currentIndex,
                children: widget.screens,
              ),
            ),
          ),
          Positioned(
            top: safePadding.top + 8,
            left: safePadding.left + 12,
            child: _AndroidMenuButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _AndroidMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AndroidMenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? AppTheme.textLight : AppTheme.textDark;
    final background =
        isDark
            ? AppTheme.charcoal.withValues(alpha: 0.84)
            : AppTheme.pureWhite.withValues(alpha: 0.96);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
      elevation: 8,
      child: IconButton(
        tooltip: 'Open navigation',
        onPressed: onPressed,
        icon: const Icon(Icons.menu_rounded),
        color: foreground,
        iconSize: 24,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(
        vsync: this,
        duration: widget.duration,
        value: i == widget.index ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      for (var controller in _controllers) {
        controller.dispose();
      }
      _controllers = List.generate(
        widget.children.length,
        (i) => AnimationController(
          vsync: this,
          duration: widget.duration,
          value: i == widget.index ? 1.0 : 0.0,
        ),
      );
    } else if (oldWidget.index != widget.index) {
      _controllers[oldWidget.index].reverse();
      _controllers[widget.index].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (i) {
        return FadeTransition(
          opacity: _controllers[i],
          child: IgnorePointer(
            ignoring: i != widget.index,
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}
