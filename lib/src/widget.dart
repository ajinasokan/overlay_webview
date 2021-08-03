import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'controller.dart';

part 'paint_bounds.dart';

/// [WebView] scaffolds initialisation, showing, hiding and disposing
/// of native WebView implementation. Also provides convenient callbacks
/// for events.
class WebView extends StatefulWidget {
  /// Providing instance of [WebViewController] will make this widget use that
  /// for all the operations. Useful when parent widget need to take control.
  final WebViewController? controller;

  /// Set [autoVisible] to false to disable automatically showing webview
  final bool autoVisible;

  /// [url] to be loaded when showing WebView
  final String? url;

  /// [onPageStart] is called when WebView starts loading a page
  final void Function(PageStartEvent)? onPageStart;

  /// [onPageEnd] is called when WebView ends loading a page
  final void Function(PageEndEvent)? onPageEnd;

  /// [onPageProgress] is called when WebView reports a progress in the loading
  final void Function(PageProgressEvent)? onPageProgress;

  /// [onPageError] is called when WebView fails to load the page
  final void Function(PageErrorEvent)? onPageError;

  /// [onPageDeny] is called when WebView blocks a URL specified in the [denyList]
  final void Function(PageDenyEvent)? onPageDeny;

  /// [onPageNewWindow] is called when WebView blocks opening a new window
  final void Function(PageNewWindowEvent)? onPageNewWindow;

  /// [onPostMessage] is called when page loaded in WebView sends a postMessage
  final void Function(PostMessageEvent)? onPostMessage;

  /// [onDownloadInit] is called when page in WebView initialises a download (only Android)
  final void Function(DownloadInitEvent)? onDownloadInit;

  /// [onDownloadStarted] is called when page in WebView starts a download (only Android)
  final void Function(DownloadStartedEvent)? onDownloadStarted;

  /// [onDownloadCancelled] is called when page in WebView cancels a download (only Android)
  final void Function(DownloadCancelledEvent)? onDownloadCancelled;

  /// [background] widget is shown until WebView is visible
  final Widget? background;

  /// [denyList] is a map of a key(eg: block_facebook) and corresponding regular expression
  /// for matching URL (eg: ^facebook.com). If match happens WebView will block the navigation
  /// and will call [onPageDeny] with the details.
  final Map<String, String>? denyList;

  /// HTML contents of [errorPage] will be rendered in webview in case a PageError
  /// occurs. HTML can have template strings: {{errorURL}} {{errorDescription}} {
  /// {errorCode}} which will get replaced with appropriate values.
  final String? errorPage;

  WebView({
    this.controller,
    this.url,
    this.autoVisible = true,
    this.onPageStart,
    this.onPageEnd,
    this.onPageProgress,
    this.onPageError,
    this.onPageDeny,
    this.onPageNewWindow,
    this.onPostMessage,
    this.onDownloadInit,
    this.onDownloadStarted,
    this.onDownloadCancelled,
    this.background,
    this.denyList,
    this.errorPage,
  });

  @override
  _WebViewState createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  WebViewController? ctrl;
  Orientation? orientation;
  Size? size;
  bool shown = false;
  Rect? position;
  StreamSubscription? subscription;
  bool disposeAfterInit = false;

  @override
  void initState() {
    initWebView();
    super.initState();
  }

  /// Initialise WebViewController and set properties
  void initWebView() async {
    WebViewController newCtrl = widget.controller ?? WebViewController();
    await newCtrl.init();
    subscription = newCtrl.eventStream.listen(onEvent);
    if (widget.url != null) newCtrl.load(widget.url!);
    if (widget.denyList != null) newCtrl.setDenyList(widget.denyList!);
    if (widget.errorPage != null) newCtrl.setErrorPage(widget.errorPage!);
    // widget got disposed while initialising
    // so cleanup resources
    if (disposeAfterInit) {
      newCtrl.hide();
      newCtrl.dispose();
      return;
    }
    if (shown) await newCtrl.show();
    if (position != null) await newCtrl.setPosition(position!);
    ctrl = newCtrl;
  }

  /// Handler to dispatch callbacks corresponding to the event
  void onEvent(WebViewEvent e) {
    if (e is PageStartEvent) widget.onPageStart?.call(e);
    if (e is PageEndEvent) widget.onPageEnd?.call(e);
    if (e is PageProgressEvent) widget.onPageProgress?.call(e);
    if (e is PageErrorEvent) widget.onPageError?.call(e);
    if (e is PageDenyEvent) widget.onPageDeny?.call(e);
    if (e is PageNewWindowEvent) widget.onPageNewWindow?.call(e);
    if (e is PostMessageEvent) widget.onPostMessage?.call(e);
    if (e is DownloadInitEvent) widget.onDownloadInit?.call(e);
    if (e is DownloadStartedEvent) widget.onDownloadStarted?.call(e);
    if (e is DownloadCancelledEvent) widget.onDownloadCancelled?.call(e);
  }

  /// Hide and dispose WebView when this widget is disposed
  @override
  void dispose() {
    shown = false;
    subscription?.cancel();
    if (widget.controller == null) {
      // if ctrl is null that means it is still being initialised
      // defer dispose to end of init function.
      if (ctrl == null) {
        disposeAfterInit = true;
      } else {
        ctrl?.hide();
        ctrl?.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PaintBounds reports the change in the position of this widget.
    // Whenever that happens update the position of WebView. And if
    // this is the first report then make WebView visible.
    return _PaintBounds(
      onBoundsChange: (Rect p) async {
        position = p;
        await ctrl?.setPosition(p);

        if (widget.autoVisible && ctrl != null && !shown) {
          await ctrl?.show();
          shown = true;
        }
      },
      child: widget.background ?? SizedBox.expand(),
    );
  }
}
