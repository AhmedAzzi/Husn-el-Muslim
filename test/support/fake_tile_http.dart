import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG (same bytes as package:transparent_image).
const _transparentPng = <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, //
  0, 0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 96, 0, 2, 0, 0, //
  5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, //
  66, 96, 130,
];

/// Stops widget tests from hitting real tile servers (e.g. OSM, which
/// answers test-runners with 400s): every HTTP response is a 200 with a
/// 1x1 PNG body. Covers both dart:io users and package:http (flutter_map
/// goes through IOClient → dart:io HttpClient, which honors this).
///
/// Register in setUp, restore in tearDown:
/// ```dart
/// HttpOverrides.global = FakeTileHttpOverrides();
/// ```
class FakeTileHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpRequest();

  @override
  void close({bool force = false}) {}
}

class _FakeHttpRequest extends Fake implements HttpClientRequest {
  final _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  set contentLength(int value) {}

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _FakeHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(_transparentPng).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  X509Certificate? get certificate => null;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      throw UnsupportedError(
          'FakeTileHttpOverrides never redirects (isRedirect is false)');

  @override
  Future<Socket> detachSocket() => throw UnsupportedError(
      'FakeTileHttpOverrides never upgrades connections');
}
