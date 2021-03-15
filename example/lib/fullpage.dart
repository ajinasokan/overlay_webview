import 'package:flutter/material.dart';
import 'package:overlay_webview/overlay_webview.dart';

class FullPage extends StatefulWidget {
  @override
  _FullPageState createState() => _FullPageState();
}

class _FullPageState extends State<FullPage> {
  final webView = WebViewController();

  @override
  void dispose() {
    webView.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        webView.hide();
        return true;
      },
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Column(
            children: <Widget>[
              RaisedButton(
                child: Text("Launch"),
                onPressed: () {
                  webView.load("https://google.com");
                },
              ),
              Expanded(
                child: WebView(
                  controller: webView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
