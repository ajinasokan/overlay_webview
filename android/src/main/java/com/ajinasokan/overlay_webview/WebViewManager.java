package com.ajinasokan.overlay_webview;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Message;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class WebViewManager {
    WebView webView;
    DownloadHandler downloadHandler;
    String webViewID;
    public HashMap<String, Pattern> denyPatterns;
    private OverlayWebviewPlugin plugin;
    public String errorPage;

    WebViewManager(OverlayWebviewPlugin plugin, String webViewID) {
        this.plugin = plugin;
        this.webViewID = webViewID;
    }

    void eval(final String id, final String expression) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            webView.evaluateJavascript(expression, new ValueCallback<String>() {
                @Override
                public void onReceiveValue(final String result) {
                    plugin.sendEvent(webViewID,"exec_result", new HashMap<String, Object>(){ {
                        put("id", id);
                        put("result", result);
                    }});
                }
            });
        }
    }

    @SuppressLint({"AddJavascriptInterface", "SetJavaScriptEnabled"})
    void init() {
        if(webView != null) {
            if(webView.getParent() == null) {
                addToActivity();
            } else {
                hide();
            }
            return;
        }

        webView = new WebView(PermissionHandler.getActivity());

        downloadHandler = new DownloadHandler(plugin, webViewID);
        webView.addJavascriptInterface(new WebViewBridge(), "WebViewBridge");
        webView.setDownloadListener(downloadHandler);

        webView.getSettings().setSupportMultipleWindows(true);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setAllowContentAccess(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setAppCacheEnabled(true);
        
        // webView.getSettings().setLoadWithOverviewMode(true);
        // webView.getSettings().setUseWideViewPort(true);

        webView.getSettings().setSupportZoom(true);
        webView.getSettings().setBuiltInZoomControls(true);
        webView.getSettings().setDisplayZoomControls(false);

        // webView.setScrollBarStyle(WebView.SCROLLBARS_OUTSIDE_OVERLAY);
        // webView.setScrollbarFadingEnabled(false);

        // webView.getSettings().setUserAgentString("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36");

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(final WebView view, final String url, Bitmap favicon) {
                plugin.sendEvent(webViewID,"page_start", new HashMap<String, Object>(){ {
                    put("url", url);
                    put("can_go_back", view.canGoBack());
                    put("can_go_forward", view.canGoForward());
                }});
            }

            @Override
            public void onPageFinished(final WebView view, final String url) {
                plugin.sendEvent(webViewID,"page_end", new HashMap<String, Object>(){ {
                    put("url", url);
                    put("can_go_back", view.canGoBack());
                    put("can_go_forward", view.canGoForward());
                }});
            }

            public void onReceivedError(final WebView view, final int errorCode, final String description, final String failingUrl) {
                if (view == null)
                    return;
                plugin.sendEvent(webViewID,"page_error", new HashMap<String, Object>(){ {
                    put("url", failingUrl);
                    put("code", errorCode);
                    put("description", description);

                    put("can_go_back", view.canGoBack());
                    put("can_go_forward", view.canGoForward());
                }});
                if(errorPage != null) {
                    String html = errorPage
                            .replaceAll("\\{\\{errorURL\\}\\}", failingUrl)
                            .replaceAll("\\{\\{errorCode\\}\\}", errorCode+"")
                            .replaceAll("\\{\\{errorDescription\\}\\}", description);
                    loadHTML(html);
                }
            }

            @TargetApi(android.os.Build.VERSION_CODES.M)
            @Override
            public void onReceivedError(final WebView view, WebResourceRequest request, final WebResourceError error) {
                if (view == null)
                    return;

                if (request.isForMainFrame()) {
                    final String currentUrl = request.getUrl().toString();
                    plugin.sendEvent(webViewID,"page_error", new HashMap<String, Object>(){ {
                        put("url", currentUrl);
                        put("code", error.getErrorCode());
                        put("description", error.getDescription().toString());

                        put("can_go_back", view.canGoBack());
                        put("can_go_forward", view.canGoForward());
                    }});
                    if(errorPage != null) {
                        String html = errorPage
                                .replaceAll("\\{\\{errorURL\\}\\}", currentUrl)
                                .replaceAll("\\{\\{errorCode\\}\\}", error.getErrorCode()+"")
                                .replaceAll("\\{\\{errorDescription\\}\\}", error.getDescription().toString());
                        loadHTML(html);
                    }
                }
            }

            @Override
            public boolean shouldOverrideUrlLoading(final WebView view, final String url) {
                plugin.sendEvent(webViewID,"page_progress", new HashMap<String, Object>(){ {
                    put("url", url);

                    put("can_go_back", view.canGoBack());
                    put("can_go_forward", view.canGoForward());
                }});

                if (denyPatterns == null)
                    return false;

                Object[] keys = denyPatterns.keySet().toArray();
                for (int i = 0; i < keys.length; i++) {
                    Pattern p = denyPatterns.get(keys[i]);
                    Matcher m = p.matcher(url);

                    if (m.find()) {
                        final String key = keys[i].toString();
                        plugin.sendEvent(webViewID,"page_deny", new HashMap<String, Object>(){ {
                            put("key", key);
                            put("url", url);
                            put("can_go_back", view.canGoBack());
                            put("can_go_forward", view.canGoForward());
                        }});
                        return true;
                    }
                }
                return false;
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onCreateWindow(final WebView view, boolean dialog, boolean userGesture, Message resultMsg)
            {
                plugin.sendEvent(webViewID,"page_new_window", new HashMap<String, Object>(){ {
                    put("url", view.getHitTestResult().getExtra());
                    put("can_go_back", view.canGoBack());
                    put("can_go_forward", view.canGoForward());
                }});
                return false;
            }
        });

        addToActivity();
    }

    void dispose() {
        hide();
        removeFromActivity();
        webView.destroy();
        webView = null;
    }

    void addToActivity() {
        FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        );
        hide();
        PermissionHandler.getActivity().addContentView(webView, layoutParams);
    }

    void removeFromActivity() {
        ((ViewGroup) (webView.getParent())).removeView(webView);
    }

    void permissionCallback() {
        downloadHandler.startDownload();
    }

    void load(String url) {
        webView.loadUrl(url);
    }

    void loadHTML(String html) {
        // loadData requires url encoding, loadDataWithBaseURL doesnt
        // Refer: https://developer.android.com/reference/android/webkit/WebView#loadDataWithBaseURL(java.lang.String,%20java.lang.String,%20java.lang.String,%20java.lang.String,%20java.lang.String)
        webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
    }

    void enableDebugging(boolean value) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(value);
        }
    }

    void position(int l, int t, int w, int h) {
        if (webView.getLayoutParams() instanceof ViewGroup.MarginLayoutParams) {
            ViewGroup.MarginLayoutParams p = (ViewGroup.MarginLayoutParams) webView.getLayoutParams();
            p.width = pxFromDp(w);
            p.height = pxFromDp(h);
            p.setMargins(pxFromDp(l), pxFromDp(t), 0, 0);
            webView.requestLayout();
        }
    }

    void setDenyList(Map denyList) {
        HashMap<String, Pattern> patterns = new HashMap<>();
        Object[] keys = denyList.keySet().toArray();
        for (int i = 0; i < keys.length; i++) {
            Pattern p = Pattern.compile(denyList.get(keys[i]).toString());
            patterns.put(keys[i].toString(), p);
        }
        denyPatterns = patterns;
    }

    void show() {
        webView.setVisibility(View.VISIBLE);
        webView.bringToFront();
    }

    void hide() {
        webView.setVisibility(View.GONE);
    }

    void reload() {
        webView.reload();
    }

    void back() {
        webView.goBack();
    }

    void forward() {
        webView.goForward();
    }

    public int pxFromDp(final int dp) {
        return (int) (dp * PermissionHandler.getActivity().getResources().getDisplayMetrics().density);
    }

    protected class WebViewBridge {
        @JavascriptInterface
        public void postMessage(final String message) {
            PermissionHandler.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    plugin.sendEvent(webViewID,"post_message", new HashMap<String, Object>(){ {
                        put("message", message);
                    }});
                }
            });
        }
    }
}
