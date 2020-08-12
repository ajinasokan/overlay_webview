package com.ajinasokan.overlay_webview;

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
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** OverlayWebviewPlugin */
public class OverlayWebviewPlugin implements FlutterPlugin, MethodCallHandler, StreamHandler, ActivityAware {
  private static final String METHOD_CHANNEL = "overlay_webview";
  private static final String EVENT_CHANNEL = "overlay_webview_events";

  private EventSink webViewEvents;

  final PermissionHandler permissionHandler = new PermissionHandler(this);
  final HashMap<String, WebViewManager> webviews = new HashMap<>();

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    String webViewID = call.argument("id");

    if (call.method.equals("init")) {
      if(!webviews.containsKey(webViewID))
        webviews.put(webViewID, new WebViewManager(this, webViewID));
      webviews.get(webViewID).init();
    } else if(call.method.equals("dispose")) {
      webviews.get(webViewID).dispose();
      webviews.remove(webViewID);
    } else if (call.method.equals("show")) {
      webviews.get(webViewID).show();
    } else if (call.method.equals("hide")) {
      webviews.get(webViewID).hide();
    } else if (call.method.equals("reload")) {
      webviews.get(webViewID).reload();
    } else if (call.method.equals("back")) {
      webviews.get(webViewID).back();
    } else if (call.method.equals("forward")) {
      webviews.get(webViewID).forward();
    } else if (call.method.equals("load")) {
      webviews.get(webViewID).load((String) call.argument("url"));
    } else if (call.method.equals("loadHTML")) {
      webviews.get(webViewID).loadHTML((String) call.argument("html"));
    } else if (call.method.equals("position")) {
      webviews.get(webViewID).position(
              (int) call.argument("l"),
              (int) call.argument("t"),
              (int) call.argument("w"),
              (int) call.argument("h")
      );
    } else if (call.method.equals("denyList")) {
      webviews.get(webViewID).setDenyList((Map)call.argument("items"));
    } else if (call.method.equals("exec")) {
      String execID = call.argument("exec_id");
      String expression = call.argument("expression");
      webviews.get(webViewID).eval(execID, expression);
    } else if (call.method.equals("activeWebViews")) {
      ArrayList<String> webViewIDs = new ArrayList<>(webviews.keySet());
      result.success(webViewIDs);
      return;
    } else if (call.method.equals("disposeAll")) {
      for (String id: webviews.keySet()) {
        webviews.get(id).dispose();
        webviews.remove(id);
      }
      return;
    }  else {
      result.notImplemented();
      return;
    }
    result.success(null);
  }

  void permissionCallback(String webViewID) {
    webviews.get(webViewID).permissionCallback();
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

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), METHOD_CHANNEL);
    final EventChannel events = new EventChannel(registrar.messenger(), EVENT_CHANNEL);
    OverlayWebviewPlugin instance = new OverlayWebviewPlugin();
    PermissionHandler.setActivity(registrar.activity());
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
