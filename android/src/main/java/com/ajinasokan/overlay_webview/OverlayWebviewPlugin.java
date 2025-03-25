package com.ajinasokan.overlay_webview;

import android.content.Context;
import android.os.Build;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.ValueCallback;
import android.webkit.WebStorage;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * OverlayWebviewPlugin
 */
public class OverlayWebviewPlugin implements FlutterPlugin, MethodCallHandler, StreamHandler, ActivityAware {
    private static final String METHOD_CHANNEL = "overlay_webview";
    private static final String EVENT_CHANNEL = "overlay_webview_events";

    private EventSink webViewEvents;

    final PermissionHandler permissionHandler = new PermissionHandler(this);
    final HashMap<String, WebViewManager> webViews = new HashMap<>();

    // From: https://github.com/react-native-cookies/cookies/blob/master/android/src/main/java/com/reactnativecommunity/cookies/CookieManagerModule.java
    private CookieSyncManager mCookieSyncManager;

    private void initCookieSyncManager(Context context) {
        this.mCookieSyncManager = CookieSyncManager.createInstance(context);
    }

    private CookieManager getCookieManager() throws Exception {
        try {
            CookieManager cookieManager = CookieManager.getInstance();
            cookieManager.setAcceptCookie(true);
            return cookieManager;
        } catch (Exception e) {
            throw new Exception(e);
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        String webViewID = call.argument("id");
        WebViewManager webView = webViews.get(webViewID);

        if (call.method.equals("init")) {
            if (webView != null) {
                // initialising already initialised webview
                result.error("webview_already_initialised", "WebView with ID " + webViewID + " was already initialised", null);
                return;
            } else {
                webView = new WebViewManager(this, webViewID);
                webViews.put(webViewID, webView);
            }
            webView.init();
        } else if (call.method.equals("activeWebViews")) {
            ArrayList<String> activeIDs = new ArrayList<>();
            for (String id : webViews.keySet()) {
                // after dispose the value is set to null
                // so filter those out and send only active ones
                if (webViews.get(id) != null) {
                    activeIDs.add(id);
                }
            }
            result.success(activeIDs);
            return;
        } else if (call.method.equals("disposeAll")) {
            for (Map.Entry<String, WebViewManager> entry : webViews.entrySet()) {
                if(entry.getValue() != null) {
                    entry.getValue().dispose();
                }
                entry.setValue(null);
            }
        } else if (call.method.equals("clearCookies")) {
            try {
                CookieManager cookieManager = getCookieManager();
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
                    cookieManager.removeAllCookie();
                    cookieManager.removeSessionCookie();
                    mCookieSyncManager.sync();
                    result.success(null);
                    return;
                } else {
                    cookieManager.removeAllCookies(new ValueCallback<Boolean>() {
                        @Override
                        public void onReceiveValue(Boolean value) {
                            result.success(null);
                        }
                    });
                    cookieManager.flush();
                    return;
                }
            } catch (Exception e) {
                result.error("cookie_clear_fail", "Unable to clear cookies. Exception: " + e.getMessage(), null);
                return;
            }
        } else if (call.method.equals("clearStorage")) {
            try {
                WebStorage.getInstance().deleteAllData();
                result.success(null);
                return;
            } catch (Exception e) {
                result.error("storage_clear_fail", "Unable to clear storage. Exception: " + e.getMessage(), null);
                return;
            }
        } else if (call.method.equals("clearCache")) {
            try {
                webView.clearCache();
                result.success(null);
                return;
            } catch (Exception e) {
                result.error("cache_clear_fail", "Unable to clear cache. Exception: " + e.getMessage(), null);
                return;
            }
        } else {
            // using before init
            if (!webViews.containsKey(webViewID)) {
                result.error("webview_not_found", "WebView with ID " + webViewID + " not found", null);
                return;
            }
            // using after dispose
            if (webView == null) {
                result.error("webview_disposed", "WebView with ID " + webViewID + " was already disposed", null);
                return;
            }
            if (call.method.equals("dispose")) {
                webView.dispose();
                // set to null to track use-after-dispose
                webViews.put(webViewID, null);
            } else if (call.method.equals("show")) {
                webView.show();
            } else if (call.method.equals("hide")) {
                webView.hide();
            } else if (call.method.equals("isVisible")) {
                result.success(webView.isVisible());
                return;
            } else if (call.method.equals("reload")) {
                webView.reload();
            } else if (call.method.equals("back")) {
                webView.back();
            } else if (call.method.equals("forward")) {
                webView.forward();
            } else if (call.method.equals("load")) {
                webView.load((String) call.argument("url"));
            } else if (call.method.equals("loadHTML")) {
                webView.loadHTML((String) call.argument("html"), (String) call.argument("base_url"));
            } else if (call.method.equals("errorPage")) {
                webView.errorPage = ((String) call.argument("html"));
            } else if (call.method.equals("enableDebugging")) {
                webView.enableDebugging((boolean) call.argument("value"));
            } else if (call.method.equals("position")) {
                webView.position(
                        (int) call.argument("l"),
                        (int) call.argument("t"),
                        (int) call.argument("w"),
                        (int) call.argument("h")
                );
            } else if (call.method.equals("denyList")) {
                webView.setDenyList((Map) call.argument("items"));
            } else if (call.method.equals("userAgent")) {
                webView.setUserAgent((String) call.argument("user_agent"));
            } else if (call.method.equals("exec")) {
                String execID = call.argument("exec_id");
                String expression = call.argument("expression");
                webView.eval(execID, expression);
            } else {
                result.notImplemented();
                return;
            }
        }
        result.success(null);
    }

    void permissionCallback(String webViewID) {
        WebViewManager webView = webViews.get(webViewID);
        if (webView != null) {
            webView.permissionCallback();
        }
    }

    void sendEvent(String id, String type, Map<String, Object> data) {
        if (webViewEvents == null)
            return;

        Map<String, Object> event = new HashMap<>();
        event.put("id", id);
        event.put("type", type);
        event.put("data", data);
        webViewEvents.success(event);
    }

    // Plugin related stuff

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        final MethodChannel channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), METHOD_CHANNEL);
        final EventChannel events = new EventChannel(flutterPluginBinding.getBinaryMessenger(), EVENT_CHANNEL);
        OverlayWebviewPlugin instance = new OverlayWebviewPlugin();
        channel.setMethodCallHandler(instance);
        events.setStreamHandler(instance);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    }

    @Override
    public void onListen(Object arguments, EventSink events) {
        webViewEvents = events;
    }

    @Override
    public void onCancel(Object arguments) {
        webViewEvents = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        PermissionHandler.setActivity(binding.getActivity());
        initCookieSyncManager(binding.getActivity());
        binding.addRequestPermissionsResultListener(permissionHandler);
    }

    @Override
    public void onDetachedFromActivity() {
        PermissionHandler.setActivity(null);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }
}
