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
            children: <Widget>[
              ElevatedButton(
                child: Text("Toggle width"),
                onPressed: () async {
                  setState(() {
                    isInf = !isInf;
                  });
                },
              ),
              ElevatedButton(
                child: Text("Active WebViews"),
                onPressed: () async {
                  print(await WebViewController.activeWebViews());
                },
              ),
              ElevatedButton(
                child: Text("Dispose All"),
                onPressed: () async {
                  await WebViewController.disposeAll();
                },
              ),
              ElevatedButton(
                child: Text("Init"),
                onPressed: () async {
                  await webView.init();
                  isInit = true;
                  setState(() {});
                },
              ),
              ElevatedButton(
                child: Text("Google"),
                onPressed: () {
                  webView.load("https://google.com");
                },
              ),
              ElevatedButton(
                child: Text("DO"),
                onPressed: () {
                  webView.load("http://speedtest-blr1.digitalocean.com");
                },
              ),
              ElevatedButton(
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
              ElevatedButton(
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
              ElevatedButton(
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
              ElevatedButton(
                child: Text("Show"),
                onPressed: () {
                  webView.show();
                },
              ),
              ElevatedButton(
                child: Text("Set Pos"),
                onPressed: () {
                  webView.setPosition(Rect.fromLTWH(0, 400, 400, 300));
                },
              ),
              ElevatedButton(
                child: Text("Hide"),
                onPressed: () {
                  webView.hide();
                },
              ),
              ElevatedButton(
                child: Text("Exec"),
                onPressed: () async {
                  print(await webView
                      .exec("JSON.parse(JSON.stringify(window.location))"));
                },
              ),
              ElevatedButton(
                child: Text("Deny Google"),
                onPressed: () {
                  webView.setDenyList({
                    "block_google": ".*?google.com.*",
                  });
                },
              ),
              ElevatedButton(
                child: Text("Fullpage"),
                onPressed: () async {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => FullPage()));
                },
              ),
              ElevatedButton(
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
              ElevatedButton(
                child: Text("Back"),
                onPressed: () async {
                  webView.back();
                },
              ),
              ElevatedButton(
                child: Text("Forward"),
                onPressed: () async {
                  webView.forward();
                },
              ),
              ElevatedButton(
                child: Text("Error load mainFrame"),
                onPressed: () async {
                  webView.load("http://google.com");
                },
              ),
              ElevatedButton(
                child: Text("Error load iframe"),
                onPressed: () async {
                  webView.loadHTML("""
                  <iframe src='http://google.com'>
                  """);
                },
              ),
              ElevatedButton(
                child: Text("Dialogs"),
                onPressed: () async {
                  webView.loadHTML("""
                  <button onclick="alert('alert');">Alert</button>
                  <button onclick="confirm('confirm');">Confirm</button>
                  <button onclick="prompt('prompt','defaultText');">Prompt</button>
                  """);
                },
              ),
              ElevatedButton(
                child: Text("Clear cookies"),
                onPressed: () async {
                  await webView.clearCookies();
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
