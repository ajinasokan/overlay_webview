import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/services.dart';

// import 'package:overlay_webview_example/main.dart' as app;

import 'package:overlay_webview/overlay_webview.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // app.main();
  // await tester.pumpAndSettle();

  testWidgets("initialise webview", (WidgetTester tester) async {
    final webView = WebViewController(id: "main1");
    await webView.init();
    final active = await WebViewController.activeWebViews();

    expect(active.length, equals(1));
    expect(active[0], equals("main1"));
  });

  testWidgets("dispose all webviews", (WidgetTester tester) async {
    final webView = WebViewController(id: "main2");
    await webView.init();
    await WebViewController.disposeAll();
    final active = await WebViewController.activeWebViews();

    expect(active.length, equals(0));
  });

  testWidgets("catch use after dispose", (WidgetTester tester) async {
    final webView = WebViewController(id: "main3");
    await webView.init();
    await WebViewController.disposeAll();

    expect(
        () => webView.show(),
        throwsA(predicate(
            (e) => e is PlatformException && e.code == "webview_disposed")));
  });

  testWidgets("catch use before init", (WidgetTester tester) async {
    final webView = WebViewController(id: "main4");

    expect(
        () => webView.show(),
        throwsA(predicate(
            (e) => e is PlatformException && e.code == "webview_not_found")));
  });

  testWidgets("catch double init", (WidgetTester tester) async {
    final webView = WebViewController(id: "main5");
    await webView.init();

    expect(
        () => webView.init(),
        throwsA(predicate((e) =>
            e is PlatformException &&
            e.code == "webview_already_initialised")));
  });
}
