#import "OverlayWebviewPlugin.h"
#if __has_include(<overlay_webview/overlay_webview-Swift.h>)
#import <overlay_webview/overlay_webview-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "overlay_webview-Swift.h"
#endif

@implementation OverlayWebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOverlayWebviewPlugin registerWithRegistrar:registrar];
}
@end
