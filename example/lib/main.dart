import 'package:flutter/material.dart';
import 'package:overlay_webview/overlay_webview.dart';
import 'fullpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WebViewController.disposeAll();
  runApp(
    MaterialApp(
      home: MyApp(),
      navigatorObservers: [],
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  WebViewController webView = WebViewController(id: "main");
  bool isInit = false;
  bool isInf = false;

  @override
  void initState() {
    super.initState();
  }

  Widget smallButton({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        color: Colors.blue,
        padding: EdgeInsets.all(4),
        margin: EdgeInsets.all(2),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).viewPadding.top),
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: <Widget>[
              smallButton(
                child: Text("Toggle width"),
                onPressed: () async {
                  setState(() {
                    isInf = !isInf;
                  });
                },
              ),
              smallButton(
                child: Text("Active WebViews"),
                onPressed: () async {
                  print(await WebViewController.activeWebViews());
                },
              ),
              smallButton(
                child: Text("Dispose All"),
                onPressed: () async {
                  await WebViewController.disposeAll();
                },
              ),
              smallButton(
                child: Text("Init"),
                onPressed: () async {
                  await webView.init();
                  isInit = true;
                  setState(() {});
                },
              ),
              smallButton(
                child: Text("Google"),
                onPressed: () {
                  webView.load("https://google.com");
                },
              ),
              smallButton(
                child: Text("DO"),
                onPressed: () {
                  webView.load("http://speedtest-blr1.digitalocean.com");
                },
              ),
              smallButton(
                child: Text("Downloads"),
                onPressed: () {
                  webView.loadHTML("""
                  <a href="javascript:download()">
                    Click to download
                  </a>

                  <script>
                  var saveData = (function () {
                    var a = document.createElement("a");
                    document.body.appendChild(a);
                    a.style = "display: none";
                    return function (data, fileName) {
                        var json = JSON.stringify(data),
                            blob = new Blob([json], {type: "octet/stream"}),
                            url = window.URL.createObjectURL(blob);
                        a.href = url;
                        a.download = fileName;
                        a.click();
                        window.URL.revokeObjectURL(url);
                    };
                }());

                var data = { x: 42, s: "hello, world", d: new Date() },
                    fileName = "my-download.json";

                  function download() {
                    saveData(data, fileName);
                  }
                  </script>
                  """);
                },
              ),
              smallButton(
                child: Text("onMessage"),
                onPressed: () {
                  webView.loadHTML("""
                    hello
                    <script>
                    if(window.WebViewBridge) {
                      window.WebViewBridge.postMessage("hello");
                      document.body.innerHTML = "android bridge";
                    }
                    
                    if(window.webkit.messageHandlers.WebViewBridge) {
                      window.webkit.messageHandlers.WebViewBridge.postMessage("hello");
                      document.body.innerHTML = "ios bridge";
                    }
                    </script>
                  """);
                },
              ),
              smallButton(
                child: Text("Post Message"),
                onPressed: () async {
                  await webView.loadHTML("""
                    hello
                    <script>
                      window.addEventListener("message", receiveMessage, false);

                      function receiveMessage(event) {
                        document.body.innerHTML = event.data;

                        window.WebViewBridge.postMessage("hello from webview");
                      }
                    </script>
                  """);
                  await webView.postMessage("hello from flutter");
                },
              ),
              smallButton(
                child: Text("Show"),
                onPressed: () {
                  webView.show();
                },
              ),
              smallButton(
                child: Text("Set Pos"),
                onPressed: () {
                  webView.setPosition(Rect.fromLTWH(0, 400, 400, 300));
                },
              ),
              smallButton(
                child: Text("Hide"),
                onPressed: () {
                  webView.hide();
                },
              ),
              smallButton(
                child: Text("Exec"),
                onPressed: () async {
                  print(await webView
                      .exec("JSON.parse(JSON.stringify(window.location))"));
                },
              ),
              smallButton(
                child: Text("Deny Google"),
                onPressed: () {
                  webView.setDenyList({
                    "block_google": ".*?google.com.*",
                  });
                },
              ),
              smallButton(
                child: Text("Fullpage"),
                onPressed: () async {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => FullPage()));
                },
              ),
              smallButton(
                child: Text("Window creation"),
                onPressed: () async {
                  await webView.loadHTML("""
                    <a href="https://google.com" target="_blank">Google in new window</a>
                    <a href="https://google.com" target="_blank">
                      <img src="https://ssl.gstatic.com/ui/v1/icons/mail/rfr/logo_chat_default_1x.png" />
                    </a>
                  """);
                },
              ),
              smallButton(
                child: Text("Back"),
                onPressed: () async {
                  webView.back();
                },
              ),
              smallButton(
                child: Text("Forward"),
                onPressed: () async {
                  webView.forward();
                },
              ),
              smallButton(
                child: Text("Error load mainFrame"),
                onPressed: () async {
                  webView.load("http://google.com");
                },
              ),
              smallButton(
                child: Text("Error load iframe"),
                onPressed: () async {
                  webView.loadHTML("""
                  <iframe width=800 height=800 src='http://google.com'>
                  """);
                },
              ),
              smallButton(
                child: Text("Dialogs"),
                onPressed: () async {
                  webView.loadHTML("""
                  <button onclick="alert('alert');">Alert</button>
                  <button onclick="confirm('confirm');">Confirm</button>
                  <button onclick="prompt('prompt','defaultText');">Prompt</button>
                  """);
                },
              ),
              smallButton(
                child: Text("loadHTML without baseURL"),
                onPressed: () async {
                  webView.loadHTML("""
                  <script>
                    document.write("<h1>" + window.location + "</h1>");
                  </script>
                  """);
                },
              ),
              smallButton(
                child: Text("loadHTML with baseURL"),
                onPressed: () async {
                  webView.loadHTML("""
                  <script>
                    document.write("<h1>" + window.location + "</h1>");
                  </script>
                  """, baseURL: "https://google.com");
                },
              ),
              smallButton(
                child: Text("Show webview info"),
                onPressed: () async {
                  webView.loadHTML("""
                  <script>
                    document.write("Localstorage of google.com: <p>" + Object.entries(localStorage) + "</p>");
                    document.write("Cookies of google.com: <p>" + document.cookie + "</p>");
                    document.write("User agent: <p>" + navigator.userAgent + "</p>");
                  </script>
                  """, baseURL: "https://www.google.com");
                },
              ),
              smallButton(
                child: Text("Clear cookies"),
                onPressed: () async {
                  await webView.clearCookies();
                },
              ),
              smallButton(
                child: Text("Clear storage"),
                onPressed: () async {
                  await webView.clearStorage();
                },
              ),
              smallButton(
                child: Text("Clear cache"),
                onPressed: () async {
                  await webView.clearCache();
                },
              ),
              smallButton(
                child: Text("Change user agent"),
                onPressed: () async {
                  await webView.setUserAgent("Test UA");
                },
              ),
              smallButton(
                child: Text("Rebuild control"),
                onPressed: () async {
                  await webView.dispose();
                  webView = WebViewController(id: "main");
                  await webView.init();
                  setState(() {});
                },
              ),
              smallButton(
                child: Text("Rebuild without shared worker"),
                onPressed: () async {
                  await webView.dispose();
                  webView = WebViewController(id: "main");
                  await webView.init(disableSharedWorker: true);
                  setState(() {});
                },
              ),
              smallButton(
                child: Text("isVisible"),
                onPressed: () async {
                  print(await webView.isVisible());
                },
              ),
              smallButton(
                child: Text("JS window.open"),
                onPressed: () async {
                  webView.loadHTML("""
                  <button onclick="window.open('https://google.com')">Call window.open</button>
                  """);
                },
              ),
            ],
          ),
          // Expanded(
          //   child: isInit
          //       ? WebViewFrame(
          //           child: SizedBox.expand(),
          //           controller: webView,
          //         )
          //       : SizedBox.expand(),
          // )
          Expanded(
            child: Container(
              width: isInf ? double.infinity : null,
              decoration: BoxDecoration(
                border: Border.all(width: 5, color: Colors.red),
              ),
              child: WebView(
                url: "https://google.com",
                controller: webView,
                // enableDebugging: true,
                onPageNewWindow: (e) {
                  print("onPageNewWindow ${e.url}");
                },
                onPageError: (e) {
                  print("errorCode ${e.errorCode}");
                  print("errorDesc ${e.errorDescription}");
                },
                onPageEnd: (e) {
                  print("onPageEnd ${e.url}");
                },
                errorPage: "custom error page<br>"
                    "errorCode: {{errorCode}}<br>"
                    "errorDescription: {{errorDescription}}<br>"
                    "errorURL: {{errorURL}}<br>",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
