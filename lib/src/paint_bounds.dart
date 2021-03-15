part of 'widget.dart';

/// [_PaintBounds] reports the change in its position. Used to automatically
/// position WebViews
class _PaintBounds extends SingleChildRenderObjectWidget {
  final ValueChanged<Rect> onBoundsChange;

  _PaintBounds({
    required Widget child,
    required this.onBoundsChange,
  }) : super(child: child);

  @override
  _PaintBoundsRender createRenderObject(BuildContext context) =>
      _PaintBoundsRender(onBoundsChange: onBoundsChange);
}

class _PaintBoundsRender extends RenderProxyBox {
  final ValueChanged<Rect> onBoundsChange;

  _PaintBoundsRender({required this.onBoundsChange});

  Rect lastRect = Rect.zero;

  @override
  void performLayout() {
    super.performLayout();
    onBoundsChange(lastRect);
  }

  @override
  void performResize() {
    super.performResize();
    onBoundsChange(lastRect);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final newRect = offset & constraints.biggest;
    if (lastRect != newRect) {
      onBoundsChange(newRect);
      lastRect = newRect;
    }
  }
}
