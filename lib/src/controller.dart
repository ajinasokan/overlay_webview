import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';

part 'events.dart';

MethodChannel _webview = MethodChannel('overlay_webview');
EventChannel _webviewEvents = EventChannel('overlay_webview_events');
late Stream _webviewEventsStream = _webviewEvents.receiveBroadcastStream();

int _webviewID = 0;

/// [WebViewController] handles all the operations on WebView. This is the
/// handle used in [WebView] widget. One instance is connected to one unique
/// WebView instance in the platform. They are connected by an autoincremented ID.
class WebViewController {
  var _execID = 0;
  Map<String, Completer<dynamic>> _execs = {};
  Completer<void>? _load;
  StreamSubscription? _subscription;
  String? _id;

  final _events = StreamController<WebViewEvent>.broadcast();

  bool _hasDisposed = false;
  bool get hasDisposed => _hasDisposed;

  /// Returns list of active WebView instance IDs
  static Future<List<String>> activeWebViews() async {
    final webViewIDs = await _webview.invokeMethod("activeWebViews", {});
    return webViewIDs.cast<String>();
  }

  /// Cleanup all WebViews. Can be used to clear memory when using background
  /// instances of WebView.
  static Future<void> disposeAll() async {
    await _webview.invokeMethod("disposeAll", {});
  }

  /// Create instance with a unique ID
  WebViewController({String? id}) {
    if (id == null) {
      _webviewID++;
      _id = "webview_$_webviewID";
    } else {
      _id = id;
    }
  }

  /// Initialise native WebView instance and subscribe to its events
  Future<void> init() async {
    if (_subscription != null) return;
    _subscription = _webviewEventsStream
        .where((data) => data["id"] == _id)
        .listen(_onEvent);
    await _webview.invokeMethod("init", {"id": _id});
  }

  /// [eventStream] gives raw [WebViewEvent] from the instance
  Stream<WebViewEvent> get eventStream => _events.stream;

  /// Handles all the events and packs map to corresponding [WebViewEvent]
  void _onEvent(dynamic data) async {
    if (data["type"] == "exec_result") {
      final id = data["data"]["id"] as String;
      final result = data["data"]["result"];
      if (result is String)
        _execs[id]!.complete(json.decode(result));
      else if (result is Map)
        _execs[id]!.complete(result);
      else
        _execs[id]!.complete(null);
      _execs.remove(id);
    } else if (data["type"] == "page_start") {
      _events.add(PageStartEvent._(
        url: data["data"]["url"],
        canGoBack: data["data"]["can_go_back"],
        canGoForward: data["data"]["can_go_forward"],
      ));
    } else if (data["type"] == "page_end") {
      _load?.complete();
      _load = null;
      _events.add(PageEndEvent._(
        url: data["data"]["url"],
        canGoBack: data["data"]["can_go_back"],
        canGoForward: data["data"]["can_go_forward"],
      ));
    } else if (data["type"] == "page_error") {
      _load?.complete();
      _load = null;
      _events.add(PageErrorEvent._(
        url: data["data"]["url"],
        errorCode: data["data"]["code"].toString(),
        errorDescription: data["data"]["description"],
        canGoBack: data["data"]["can_go_back"],
        canGoForward: data["data"]["can_go_forward"],
      ));
    } else if (data["type"] == "page_progress") {
      _events.add(PageProgressEvent._(
        url: data["data"]["url"],
        canGoBack: data["data"]["can_go_back"],
        canGoForward: data["data"]["can_go_forward"],
      ));
    } else if (data["type"] == "page_deny") {
      _load?.complete();
      _load = null;
      _events.add(PageDenyEvent._(
        key: data["data"]["key"],
        url: data["data"]["url"],
        canGoBack: data["data"]["can_go_back"],
        canGoForward: data["data"]["can_go_forward"],
      ));
    } else if (data["type"] == "page_new_window") {
      _load?.complete();
      _load = null;
      _events.add(PageNewWindowEvent._(
        url: data["data"]["url"],
        canGoBack: data["data"]["can_go_back"],
        canGoForward: data["data"]["can_go_forward"],
      ));
    } else if (data["type"] == "post_message") {
      _events.add(PostMessageEvent._(message: data["data"]["message"]));
    } else if (data["type"] == "download_init") {
      _events.add(DownloadInitEvent._(url: data["data"]["url"]));
    } else if (data["type"] == "download_start") {
      _events.add(DownloadInitEvent._(url: data["data"]["url"]));
    } else if (data["type"] == "download_cancelled") {
      _events.add(DownloadInitEvent._(url: data["data"]["url"]));
    } else {
      // TODO: thow exception?
    }
  }

  /// Disposes the instance of WebView
  Future<void> dispose() async {
    if (_subscription == null) return;
    _webview.invokeMethod("dispose", {"id": _id});
    _subscription!.cancel();
    _events.close();
    _subscription = null;
    _hasDisposed = true;
  }

  /// Show WebView as overlay
  Future<void> show() async => _webview.invokeMethod("show", {"id": _id});

  /// Hide WebView
  Future<void> hide() async => _webview.invokeMethod("hide", {"id": _id});

  /// Reload currently loaded page
  Future<void> reload() async => _webview.invokeMethod("reload", {"id": _id});

  /// Go back to previous page
  Future<void> back() async => _webview.invokeMethod("back", {"id": _id});

  /// Go forward to next page
  Future<void> forward() async => _webview.invokeMethod("forward", {"id": _id});

  Future<bool?> enableDebugging(bool value) async =>
      _webview.invokeMethod("enableDebugging", {"id": _id, "value": value});

  /// Load [url] in the WebView. Returns [Future] that waits until page is finished
  /// loading or error happens
  Future<void> load(String url) async {
    _load = Completer();
    _webview.invokeMethod("load", {"url": url, "id": _id});
    return _load!.future;
  }

  /// Load [html] to the WebView. Returns [Future] that waits until page is finished
  /// loading
  Future<void> loadHTML(String html) async {
    _load = Completer();
    _webview.invokeMethod("loadHTML", {
      "html": html,
      "id": _id,
    });
    return _load!.future;
  }

  /// Executes given JS [expression] and returns back the [Future] containing the
  /// result or the error
  Future<dynamic> exec(String expression) async {
    final execID = "${_execID++}";
    _execs[execID] = Completer<dynamic>();
    _webview.invokeMapMethod("exec", {
      "id": _id,
      "exec_id": execID,
      "expression": expression,
    });
    return await _execs[execID]!.future;
  }

  /// Sends the given [message] to the WebView using postMessage API
  Future<dynamic> postMessage(String message) async {
    return exec("window.postMessage(${json.encode(message)})");
  }

  /// [setDenyList] sets a map of a key(eg: block_facebook) and corresponding regular expression
  /// for matching URL (eg: ^facebook.com). If match happens WebView will block the navigation
  /// and will send back [PageDenyEvent] event with the details.
  Future<void> setDenyList(Map<String, String> items) async =>
      _webview.invokeMethod("denyList", {"id": _id, "items": items});

  /// Sets the position of WebView to [p]
  Future<void> setPosition(Rect p) async {
    _webview.invokeMapMethod("position", {
      "id": _id,
      "l": p.left.toInt(),
      "t": p.top.toInt(),
      "w": p.width.toInt(),
      "h": p.height.toInt(),
    });
  }

  /// Load [html] to the WebView on client side error. HTML can have template
  /// strings: {{errorURL}} {{errorDescription}} {{errorCode}} which will get
  /// replaced with appropriate values
  Future<void> setErrorPage(String html) async {
    _load = Completer();
    _webview.invokeMethod("errorPage", {
      "html": html,
      "id": _id,
    });
    return _load!.future;
  }
}
