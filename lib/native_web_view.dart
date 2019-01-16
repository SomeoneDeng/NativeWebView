import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef void WebViewCreatedCallback(WebViewController controller);

enum JavascriptMode {
  disabled,
  unrestricted,
}

class WebView extends StatefulWidget {
  const WebView({
    Key key,
    this.onWebViewCreated,
    this.initialUrl,
    this.javascriptMode = JavascriptMode.disabled,
    this.gestureRecognizers,
  })  : assert(javascriptMode != null),
        super(key: key);

  final WebViewCreatedCallback onWebViewCreated;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  final String initialUrl;

  final JavascriptMode javascriptMode;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  _WebSettings _settings;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {},
      child: AndroidView(
        viewType: 'nativewebview',
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
        layoutDirection: TextDirection.rtl,
        creationParams: _CreationParams.fromWidget(widget).toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  @override
  void didUpdateWidget(WebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSettings(_WebSettings.fromWidget(widget));
  }

  Future<void> _updateSettings(_WebSettings settings) async {
    _settings = settings;
    final WebViewController controller = await _controller.future;
    controller._updateSettings(settings);
  }

  void _onPlatformViewCreated(int id) {
    final WebViewController controller =
        WebViewController._(id, _WebSettings.fromWidget(widget));
    _controller.complete(controller);
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated(controller);
    }
  }
}

class _CreationParams {
  _CreationParams({this.initialUrl, this.settings});

  static _CreationParams fromWidget(WebView widget) {
    return _CreationParams(
      initialUrl: widget.initialUrl,
      settings: _WebSettings.fromWidget(widget),
    );
  }

  final String initialUrl;
  final _WebSettings settings;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'initialUrl': initialUrl,
      'settings': settings.toMap(),
    };
  }
}

class _WebSettings {
  _WebSettings({
    this.javascriptMode,
  });

  static _WebSettings fromWidget(WebView widget) {
    return _WebSettings(javascriptMode: widget.javascriptMode);
  }

  final JavascriptMode javascriptMode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'jsMode': javascriptMode.index,
    };
  }

  Map<String, dynamic> updatesMap(_WebSettings newSettings) {
    if (javascriptMode == newSettings.javascriptMode) {
      return null;
    }
    return <String, dynamic>{
      'jsMode': newSettings.javascriptMode.index,
    };
  }
}

class WebViewController {
  WebViewController._(int id, _WebSettings settings)
      : _channel = MethodChannel('nativewebview_$id'),
        _settings = settings;

  final MethodChannel _channel;

  _WebSettings _settings;

  /// load html from a string content
  Future<void> loadHtmlString(String content) async {
    assert(content != null);
    return _channel.invokeMethod("loadHtmlString", content);
  }

  Future<void> loadUrl(String url) async {
    assert(url != null);
    _validateUrlString(url);
    return _channel.invokeMethod('loadUrl', url);
  }

  Future<String> currentUrl() async {
    final String url = await _channel.invokeMethod('currentUrl');
    return url;
  }

  Future<bool> canGoBack() async {
    final bool canGoBack = await _channel.invokeMethod("canGoBack");
    return canGoBack;
  }

  Future<bool> canGoForward() async {
    final bool canGoForward = await _channel.invokeMethod("canGoForward");
    return canGoForward;
  }

  Future<void> goBack() async {
    return _channel.invokeMethod("goBack");
  }

  Future<void> goForward() async {
    return _channel.invokeMethod("goForward");
  }

  Future<void> reload() async {
    return _channel.invokeMethod("reload");
  }

  Future<void> _updateSettings(_WebSettings setting) async {
    final Map<String, dynamic> updateMap = _settings.updatesMap(setting);
    if (updateMap == null) {
      return null;
    }
    _settings = setting;
    return _channel.invokeMethod('updateSettings', updateMap);
  }

  Future<String> evaluateJavascript(String javascriptString) async {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      throw FlutterError(
          'JavaScript mode must be enabled/unrestricted when calling evaluateJavascript.');
    }
    if (javascriptString == null) {
      throw ArgumentError('The argument javascriptString must not be null. ');
    }
    final String result =
        await _channel.invokeMethod('evaluateJavascript', javascriptString);
    return result;
  }
}

void _validateUrlString(String url) {
  try {
    final Uri uri = Uri.parse(url);
    if (uri.scheme.isEmpty) {
      throw ArgumentError('Missing scheme in URL string: "$url"');
    }
  } on FormatException catch (e) {
    throw ArgumentError(e);
  }
}
