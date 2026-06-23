import 'package:flutter/material.dart';

import '../models/product.dart';

/// Cross-tab navigation for the main app shell (Home, Explore, Visual Studio, Agent).
class AppShellController extends ChangeNotifier {
  AppShellController({
    required this.onTabChange,
    int initialTab = 0,
  }) : _currentIndex = initialTab;

  final void Function(int index) onTabChange;
  int _currentIndex;
  int _sessionToken = 0;

  int get currentIndex => _currentIndex;

  /// Pending Visual Studio context applied when tab 2 mounts.
  VisualStudioIntent? pendingVisualStudio;
  /// Pending AI Agent context applied when tab 3 mounts.
  AgentIntent? pendingAgent;

  int get sessionToken => _sessionToken;

  // Set when the user taps "Restart Tutorial" so the Home screen replays the
  // tour once it becomes active again.
  bool _replayTutorial = false;
  void requestTutorialReplay() {
    _replayTutorial = true;
    goToTab(0);
  }

  bool consumeTutorialReplay() {
    final v = _replayTutorial;
    _replayTutorial = false;
    return v;
  }

  void goToTab(int index) {
    _currentIndex = index;
    onTabChange(index);
    notifyListeners();
  }

  void openExplore() => goToTab(1);

  void openVisualStudio({
    Product? product,
    List<Product>? products,
    String source = 'tab',
  }) {
    _sessionToken++;
    pendingVisualStudio = VisualStudioIntent(
      token: _sessionToken,
      products: products ?? (product != null ? [product] : const []),
      source: source,
    );
    goToTab(2);
  }

  void openAgent({
    String? seedMessage,
    String? productId,
    String source = 'typed',
    bool autoSend = false,
  }) {
    _sessionToken++;
    pendingAgent = AgentIntent(
      token: _sessionToken,
      seedMessage: seedMessage,
      productId: productId,
      source: source,
      autoSend: autoSend,
    );
    goToTab(3);
  }

  VisualStudioIntent? consumeVisualStudioIntent() {
    final intent = pendingVisualStudio;
    pendingVisualStudio = null;
    return intent;
  }

  AgentIntent? consumeAgentIntent() {
    final intent = pendingAgent;
    pendingAgent = null;
    return intent;
  }

  static AppShellController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppShellScope>()
        ?.controller;
  }

  static AppShellController of(BuildContext context) {
    final c = maybeOf(context);
    assert(c != null, 'AppShellScope not found');
    return c!;
  }
}

class VisualStudioIntent {
  final int token;
  final List<Product> products;
  final String source;

  const VisualStudioIntent({
    required this.token,
    required this.products,
    required this.source,
  });
}

class AgentIntent {
  final int token;
  final String? seedMessage;
  final String? productId;
  final String source;
  final bool autoSend;

  const AgentIntent({
    required this.token,
    this.seedMessage,
    this.productId,
    required this.source,
    this.autoSend = false,
  });
}

class AppShellScope extends InheritedNotifier<AppShellController> {
  const AppShellScope({
    super.key,
    required AppShellController controller,
    required super.child,
  }) : super(notifier: controller);

  AppShellController get controller => notifier!;
}
