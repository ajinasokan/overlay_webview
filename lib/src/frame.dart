part of 'widget.dart';

/// [WebViewFrame] reports the change in its position. Used to automatically
/// position WebViews
class WebViewFrame extends SingleChildRenderObjectWidget {
  final WebViewController controller;

  WebViewFrame({
    required Widget child,
    required this.controller,
  }) : super(child: child);

  @override
  _WebViewFrameRender createRenderObject(BuildContext context) =>
      _WebViewFrameRender(controller: controller);
}

class _WebViewFrameRender extends RenderProxyBox {
  final WebViewController controller;

  _WebViewFrameRender({required this.controller});

  Rect lastRect = Rect.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final newRect = offset & constraints.biggest;
    if (lastRect != newRect) {
      controller.setPosition(newRect);
      lastRect = newRect;
    }
  }
}
