/*
 * Copyright 2019 The Sylph Authors. All rights reserved.
 * Sylph runs Flutter integration tests on real devices in the cloud.
 * Use of this source code is governed by a GPL-style license that can be
 * found in the LICENSE file.
 */

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:pub_semver/pub_semver.dart' as v;
import 'package:test/test.dart';
import 'package:tool_base/tool_base.dart';

import 'src/context.dart';

const String kPubDevHost = 'pub.dev';
const String kPubDevBasePath = 'api/packages';

void main() {
  group('pub.dev api', () {
    http.Client client;

    setUp(() {
      client = http.Client();
    });

    tearDown(() {
      client.close();
    });

    test('remote version', () async {
      const String package = 'sylph';
      final http.Response response = await client
          .get('https://$kPubDevHost/$kPubDevBasePath/$package/metrics?pretty');
      final Map<String, dynamic> metrics = jsonDecode(response.body);
      final v.Version version =
          v.Version.parse(metrics['scorecard']['packageVersion']);
      print(version);
      print(response.body);
      final DateTime versionDate =
          DateTime.parse(metrics['scorecard']['packageCreated']);
      print(versionDate);
    });
  });

  group('net', () {
    testUsingContext('remote version', () async {
      final package = 'sylph';
      final charCodes = await fetchUrl(Uri.parse(
          'https://$kPubDevHost/$kPubDevBasePath/$package/metrics?pretty'));
      final Map metrics = jsonDecode(String.fromCharCodes(charCodes));
      print(metrics);
      final versionDate =
          DateTime.parse(metrics['scorecard']['packageCreated']);
      print(versionDate);
    });
  });

  group('settings', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('local version date', () {
      final version = DateTime.parse('2019-01-01');
      final settings = fs.file('settings');
      settings.create();
      settings.writeAsString(jsonEncode({'version': '$version'}));
      final source = settings.readAsStringSync();
      print(source);
      final Map vars = jsonDecode(source);
      expect(DateTime.parse(vars['version']), version);
    });
  });

  group('pub version', () {
    testUsingContext('get version remotely', () async {
      final PubVersion pubVersion = PubVersion('sylph', 'settings');
      final String version = await pubVersion.getLatestVersion();
      expect(version, 'version');
    });
  });
}

/// The version of a published package.
///
/// Retrieves from a settings file or, if absent, from a pub server.
/// Stores in a settings file.
///
class PubVersion {
  PubVersion(this.packageName, this.settings, [this._client, this._url]);

  final String packageName;
  final String settings;
  Uri _url;
  http.Client _client;
  File _file;
  Config _config;

  http.Client get client => _client ??= http.Client();

  File get file => _file ??= fs.file(settings);

  Config get config => _config ??= Config(file);

  static const String kLatestVersion = 'latestVersion';
  static const String kVersionDate = 'versionDate';

  Uri get url => _url ??= Uri(
        scheme: 'https',
        host: kPubDevHost,
        path: '$kPubDevBasePath/$packageName/metrics',
      query: 'pretty',
      );

  Future<String> getLatestVersion() async =>
      await _getVar(kLatestVersion, 'packageVersion');

//  void setVersion(String version) => config.setValue(kVersion, version);

  Future<String> getVersionDate() async =>
      await _getVar(kVersionDate, 'packageCreated');

//  void setVersionDate(String versionDate) =>
//      config.setValue(kVersionDate, versionDate);

  Future<String> _getVar(String varName, String metric) async {
    String varValue = config.getValue(varName);
    if (varValue == null) {
      final http.Response response = await client.get(url);
      final Map<String, dynamic> metrics = jsonDecode(response.body);
      varValue = metrics['scorecard'][metric];
      config.setValue(varName, varValue);
    }
    return varValue;
  }
}

class MockFileSystem extends Mock implements FileSystem {}
