# Overlay WebView

Note: This document is WIP

A Flutter WebView plugin that shows as an overlay to Flutter app without performance overhead.

Official Flutter plugin is computationally expensive (for now). Community plugins are either on top of this official plugin or uses the same underlying mechanism. Implementation of flutter_webview_plugin is similar but is in the path to merge with official plugin.

## Features

- Supports iOS, Android, macOS
- Page navigation with events
- Javascript injection
- Postmessage API
- File downloads (only Android)
- URL blocking with Regex
- Handle window creations
- Custom error pages
- Multiple instances
- Background instances

## TODO

* [ ] Setting properties
* [ ] Simple Transitions
* [ ] Alert/Confirm dialogs iOS
* [ ] File uploads
* [ ] Camera access
* [ ] iOS downloads
* [ ] Blob downloads