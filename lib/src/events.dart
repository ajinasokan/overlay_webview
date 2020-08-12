part of 'controller.dart';

abstract class WebViewEvent {}

/// Event fired when WebView starts loading a page
class PageStartEvent extends WebViewEvent {
  final String url;
  final bool canGoBack;
  final bool canGoForward;

  PageStartEvent._({
    this.url,
    this.canGoBack,
    this.canGoForward,
  });
}

/// Event fired when WebView ends loading a page
class PageEndEvent extends WebViewEvent {
  final String url;
  final bool canGoBack;
  final bool canGoForward;

  PageEndEvent._({
    this.url,
    this.canGoBack,
    this.canGoForward,
  });
}

/// Event fired when WebView fails to load the page
class PageErrorEvent extends WebViewEvent {
  final String url;
  final String errorCode;
  final String errorDescription;
  final bool canGoBack;
  final bool canGoForward;

  PageErrorEvent._({
    this.url,
    this.errorCode,
    this.errorDescription,
    this.canGoBack,
    this.canGoForward,
  });
}

/// Event fired when WebView reports a progress in the loading
class PageProgressEvent extends WebViewEvent {
  final String url;
  final bool canGoBack;
  final bool canGoForward;

  PageProgressEvent._({
    this.url,
    this.canGoBack,
    this.canGoForward,
  });
}

/// Event fired when WebView blocks a URL specified in the [WebViewController.setDenyList]
class PageDenyEvent extends WebViewEvent {
  final String key;
  final bool canGoBack;
  final bool canGoForward;

  PageDenyEvent._({
    this.key,
    this.canGoBack,
    this.canGoForward,
  });
}

/// Event fired when WebView blocks opening a new window
class PageNewWindowEvent extends WebViewEvent {
  final String url;
  final bool canGoBack;
  final bool canGoForward;

  PageNewWindowEvent._({
    this.url,
    this.canGoBack,
    this.canGoForward,
  });
}

/// Event fired when page loaded in WebView sends a postMessage
class PostMessageEvent extends WebViewEvent {
  final String message;
  PostMessageEvent._({this.message});
}

/// Event fired when page in WebView initialises a download (only Android)
class DownloadInitEvent extends WebViewEvent {
  final String url;
  DownloadInitEvent._({this.url});
}

/// Event fired when page in WebView starts a download (only Android)
class DownloadStartedEvent extends WebViewEvent {
  final String url;
  DownloadStartedEvent._({this.url});
}

/// Event fired when page in WebView cancels a download (only Android)
class DownloadCancelledEvent extends WebViewEvent {
  final String url;
  DownloadCancelledEvent._({this.url});
}
