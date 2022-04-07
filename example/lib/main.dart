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
  final webView = WebViewController(id: "main");
  bool isInit = false;
  bool isInf = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        children: <Widget>[
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: <Widget>[
              TextButton(
                child: Text("Toggle width"),
                onPressed: () async {
                  setState(() {
                    isInf = !isInf;
                  });
                },
              ),
              TextButton(
                child: Text("Active WebViews"),
                onPressed: () async {
                  print(await WebViewController.activeWebViews());
                },
              ),
              TextButton(
                child: Text("Dispose All"),
                onPressed: () async {
                  await WebViewController.disposeAll();
                },
              ),
              TextButton(
                child: Text("Init"),
                onPressed: () async {
                  await webView.init();
                  isInit = true;
                  setState(() {});
                },
              ),
              TextButton(
                child: Text("Google"),
                onPressed: () {
                  webView.load("https://google.com");
                },
              ),
              TextButton(
                child: Text("DO"),
                onPressed: () {
                  webView.load("http://speedtest-blr1.digitalocean.com");
                },
              ),
              TextButton(
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
              TextButton(
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
              TextButton(
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
              TextButton(
                child: Text("Show"),
                onPressed: () {
                  webView.show();
                },
              ),
              TextButton(
                child: Text("Set Pos"),
                onPressed: () {
                  webView.setPosition(Rect.fromLTWH(0, 400, 400, 300));
                },
              ),
              TextButton(
                child: Text("Hide"),
                onPressed: () {
                  webView.hide();
                },
              ),
              TextButton(
                child: Text("Exec"),
                onPressed: () async {
                  print(await webView
                      .exec("JSON.parse(JSON.stringify(window.location))"));
                },
              ),
              TextButton(
                child: Text("Deny Google"),
                onPressed: () {
                  webView.setDenyList({
                    "block_google": ".*?google.com.*",
                  });
                },
              ),
              TextButton(
                child: Text("Fullpage"),
                onPressed: () async {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => FullPage()));
                },
              ),
              TextButton(
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
              TextButton(
                child: Text("Back"),
                onPressed: () async {
                  webView.back();
                },
              ),
              TextButton(
                child: Text("Forward"),
                onPressed: () async {
                  webView.forward();
                },
              ),
              TextButton(
                child: Text("Error load mainFrame"),
                onPressed: () async {
                  webView.load("http://google.com");
                },
              ),
              TextButton(
                child: Text("Error load iframe"),
                onPressed: () async {
                  webView.loadHTML("""
                  <iframe width=800 height=800 src='http://google.com'>
                  """);
                },
              ),
              TextButton(
                child: Text("Dialogs"),
                onPressed: () async {
                  webView.loadHTML("""
                  <button onclick="alert('alert');">Alert</button>
                  <button onclick="confirm('confirm');">Confirm</button>
                  <button onclick="prompt('prompt','defaultText');">Prompt</button>
                  """);
                },
              ),
              TextButton(
                child: Text("Clear cookies"),
                onPressed: () async {
                  await webView.clearCookies();
                },
              ),
              TextButton(
                child: Text("loadHTML without baseURL"),
                onPressed: () async {
                  webView.loadHTML("""
                  <script>
                    document.write("<h1>" + window.location + "</h1>");
                  </script>
                  """);
                },
              ),
              TextButton(
                child: Text("loadHTML with baseURL"),
                onPressed: () async {
                  webView.loadHTML("""
                  <script>
                    document.write("<h1>" + window.location + "</h1>");
                  </script>
                  """, baseURL: "https://google.com");
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
                onPageNewWindow: (e) {
                  print(e.url);
                },
                onPageError: (e) {
                  print(e.errorCode);
                  print(e.errorDescription);
                },
                onPageEnd: (e) {
                  print(e.url);
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
