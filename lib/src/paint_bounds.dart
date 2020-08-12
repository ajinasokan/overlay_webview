part of 'widget.dart';

/// [_PaintBounds] reports the change in its position. Used to automatically
/// position WebViews
class _PaintBounds extends SingleChildRenderObjectWidget {
  final ValueChanged<Rect> onBoundsChange;

  _PaintBounds({
    Widget child,
    this.onBoundsChange,
  }) : super(child: child);

  @override
  _PaintBoundsRender createRenderObject(BuildContext context) =>
      _PaintBoundsRender(onBoundsChange);
}

class _PaintBoundsRender extends RenderProxyBox {
  final ValueChanged<Rect> onBoundsChange;

  _PaintBoundsRender(this.onBoundsChange);

  Rect lastRect;

  @override
  void performLayout() {
    super.performLayout();
    if (lastRect != null) onBoundsChange(lastRect);
  }

  @override
  void performResize() {
    super.performResize();
    if (lastRect != null) onBoundsChange(lastRect);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final newRect = offset & paintBounds.size;
    if (lastRect != newRect) {
      onBoundsChange(newRect);
      lastRect = newRect;
    }
  }
}
