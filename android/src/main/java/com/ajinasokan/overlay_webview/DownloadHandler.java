package com.ajinasokan.overlay_webview;

import android.net.Uri;
import android.os.Environment;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.widget.Toast;

import java.util.HashMap;

import static android.content.Context.DOWNLOAD_SERVICE;

public class DownloadHandler implements DownloadListener {
    private OverlayWebviewPlugin plugin;
    private String webViewID;

    private String downloadURL = "";
    private String contentDisposition = "";
    private String mimetype = "";

    DownloadHandler(OverlayWebviewPlugin plugin, String webViewID) {
        this.plugin = plugin;
        this.webViewID = webViewID;
    }

    void startDownload() {
        if(downloadURL.startsWith("blob:")) {
            plugin.sendEvent(webViewID, "download_cancelled", new HashMap<String, Object>(){ {
                put("url", downloadURL);
            }});
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
//                plugin.webViewManager.webView.evaluateJavascript("", new ValueCallback<String>() {
//                    @Override
//                    public void onReceiveValue(final String result) {
//                        plugin.sendEvent("download_cancelled", new HashMap<String, String>(){ {
//                            put("url", url);
//                            put("content", result);
//                        }});
//                    }
//                });
//            }
            return;
        }
        android.app.DownloadManager.Request request = new android.app.DownloadManager.Request(Uri.parse(downloadURL));
        String fileName = URLUtil.guessFileName(downloadURL, contentDisposition, mimetype);
        request.allowScanningByMediaScanner();
        request.setVisibleInDownloadsUi(true);
        request.setNotificationVisibility(android.app.DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
        request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);

        String cookies = CookieManager.getInstance().getCookie(downloadURL);
        request.addRequestHeader("cookie", cookies);

        android.app.DownloadManager dm = (android.app.DownloadManager) PermissionHandler.getActivity().getSystemService(DOWNLOAD_SERVICE);
        dm.enqueue(request);

        plugin.sendEvent(webViewID, "download_start", new HashMap<String, Object>(){ {
            put("url", downloadURL);
        }});

        //To notify the Client that the file is being downloaded
        Toast.makeText(
                PermissionHandler.getActivity().getApplicationContext(),
                "Downloading file to Downloads directory",
                Toast.LENGTH_LONG
        ).show();
    }

    @Override
    public void onDownloadStart(final String downloadURL, String userAgent, String contentDisposition, String mimetype, long len) {
        plugin.sendEvent(webViewID, "download_init", new HashMap<String, Object>(){ {
            put("url", downloadURL);
        }});

        this.downloadURL = downloadURL;
        this.contentDisposition = contentDisposition;
        this.mimetype = mimetype;

        if(plugin.permissionHandler.hasStoragePermission()) {
            startDownload();
        } else {
            plugin.permissionHandler.requestStoragePermission(webViewID);
        }
    }
}
