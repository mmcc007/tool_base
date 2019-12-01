/*
 * Copyright 2019 The Sylph Authors. All rights reserved.
 * Sylph runs Flutter integration tests on real devices in the cloud.
 * Use of this source code is governed by a GPL-style license that can be
 * found in the LICENSE file.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:tool_base/src/base/file_system.dart';
import 'package:tool_base/src/base/net.dart';
import 'package:tool_base/src/cache.dart';
import 'package:tool_base/src/tool_version.dart';

import 'src/context.dart';

void main() {
  group('ToolVersion', () {
    const String settingsFileName = 'settings.json';
    const String toolName = 'sylph';
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      Cache.flutterRoot = '/';
    });

    tearDown((){
      Cache.flutterRoot = null;
    });

    testUsingContext('get version remotely', () async {
      final File settingsFile = fs.file(fs.path.join(Cache.flutterRoot, settingsFileName));
      final ToolVersion toolVersion = ToolVersion(toolName, settingsFileName);
      final String version = await toolVersion.getLatestVersion(forceRemote: true);
      final String savedVersion = jsonDecode(settingsFile.readAsStringSync())['latestVersion'];
      expect(version, savedVersion);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      HttpClientFactory: () => () => MockHttpClient(HttpStatus.ok,
          result: jsonEncode({
            "scorecard": {
              "packageName": "sylph",
              "packageVersion": "0.7.0+2",
              "updated": "2019-11-21T22:31:32.194619Z",
              "packageVersionCreated": "2019-11-20T18:17:13.527154Z",
            }
          })),
    });

    testUsingContext('get version locally', () async {
      const String settingsPath = 'settings';
      final File settings = fs.file(settingsPath);
      final DateTime now = DateTime.now();
      const String latestVersion = '1.2.3';
      settings.writeAsStringSync(jsonEncode({
        ToolVersion.kVersionDate: '$now',
        ToolVersion.kLatestVersion: latestVersion,
      }));
      final ToolVersion toolVersion = ToolVersion('sylph', settingsPath);
      final String version = await toolVersion.getLatestVersion();
      final String savedVersion = jsonDecode(fs.file(settings).readAsStringSync())[ToolVersion.kLatestVersion];
      expect(version, savedVersion);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      HttpClientFactory: () => () => MockHttpClient(HttpStatus.badRequest, result: jsonEncode(null)),
    });

    test('get installed version', () {
      final ToolVersion toolVersion = ToolVersion('sylph', null);
      final String version = toolVersion.getInstalledVersion();
      expect(version, isNotNull);
    });
  });
}

class MockHttpClient implements HttpClient {
  MockHttpClient(this.statusCode, {this.result});

  final int statusCode;
  final String result;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(statusCode, result: result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClient - $invocation';
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  MockHttpClientRequest(this.statusCode, {this.result});

  final int statusCode;
  final String result;

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(statusCode, result: result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientRequest - $invocation';
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  MockHttpClientResponse(this.statusCode, {this.result});

  @override
  final int statusCode;

  final String result;

  @override
  String get reasonPhrase => '<reason phrase>';

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  StreamSubscription<Uint8List> listen(
    void onData(Uint8List event), {
    Function onError,
    void onDone(),
    bool cancelOnError,
  }) {
    return Stream<Uint8List>.fromIterable(
            <Uint8List>[Uint8List.fromList(result.codeUnits)])
        .listen(onData,
            onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<dynamic> forEach(void Function(Uint8List element) action) {
    action(Uint8List.fromList(result.codeUnits));
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'io.HttpClientResponse - $invocation';
  }
}
