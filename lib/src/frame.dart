part of 'widget.dart';

/// [WebViewFrame] reports the change in its position. Used to automatically
/// position WebViews
class WebViewFrame extends SingleChildRenderObjectWidget {
  final WebViewController Function() getController;

  WebViewFrame({
    required Widget child,
    required this.getController,
  }) : super(child: child);

  @override
  _WebViewFrameRender createRenderObject(BuildContext context) =>
      _WebViewFrameRender(getController: getController);
}

class _WebViewFrameRender extends RenderProxyBox {
  final WebViewController Function() getController;

  _WebViewFrameRender({required this.getController});

  Rect lastRect = Rect.zero;
  WebViewController? lastCtrl;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final newRect = offset & constraints.biggest;
    if (lastRect != newRect || lastCtrl != getController()) {
      lastCtrl = getController();
      lastCtrl!.setPosition(newRect);
      lastRect = newRect;
    }
  }
}
