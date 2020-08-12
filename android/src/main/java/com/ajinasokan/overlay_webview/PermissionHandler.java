package com.ajinasokan.overlay_webview;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.widget.Toast;

import java.lang.ref.WeakReference;
import java.util.HashMap;

import io.flutter.plugin.common.PluginRegistry;

import static android.content.Context.DOWNLOAD_SERVICE;

public class PermissionHandler implements PluginRegistry.RequestPermissionsResultListener {
    private OverlayWebviewPlugin plugin;

    private static WeakReference<Activity> activity = new WeakReference<>(null);;

    static Activity getActivity() {
        return activity.get();
    }

    static void setActivity(Activity instance) {
        activity = new WeakReference<>(instance);
    }

    final int STORAGE_REQUEST = 44578;
    String webViewID;

    PermissionHandler(OverlayWebviewPlugin plugin) {
        this.plugin = plugin;
    }

    public boolean hasStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PermissionHandler.getActivity().checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    public void requestStoragePermission(String webViewID) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PermissionHandler.getActivity().requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, STORAGE_REQUEST);
            this.webViewID = webViewID;
        } else {
            this.webViewID = null;
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if(requestCode == STORAGE_REQUEST &&
                permissions.length > 0 &&
                grantResults.length > 0 &&
                permissions[0].equals(Manifest.permission.WRITE_EXTERNAL_STORAGE ) &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            plugin.permissionCallback(webViewID);
            return true;
        }
        return false;
    }
}
