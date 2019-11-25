import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:tool_base/src/base/config.dart';
import 'package:tool_base/src/base/file_system.dart';
import 'package:tool_base/src/base/net.dart';

/// A persistent version of a published package.
///
/// Retrieves from a settings file or, if absent, from a pub server.
/// Stores in a settings file.
///
class ToolVersion {
  ToolVersion(this.packageName, this.settingsPath, [this._url]);

  final String packageName;
  final String settingsPath;
  Uri _url;

//  http.Client _client;
  File _file;
  Config _config;

//  http.Client get client => _client ??= http.Client();

  File get file => _file ??= fs.file(settingsPath);

  Config get config => _config ??= Config(file);

  static const String _kPubDevHost = 'pub.dev';
  static const String _kPubDevBasePath = 'api/packages';

  Uri get url => _url ??= Uri(
    scheme: 'https',
    host: _kPubDevHost,
    path: '$_kPubDevBasePath/$packageName/metrics',
    query: 'pretty',
  );

  static const String kLatestVersion = 'latestVersion';
  static const String kVersionDate = 'versionDate';

  Future<String> getLatestVersion() async =>
      await _getVar(kLatestVersion, 'packageVersion');

//  void setVersion(String version) => config.setValue(kVersion, version);

  Future<String> getVersionDate() async =>
      await _getVar(kVersionDate, 'updated');

//  void setVersionDate(String versionDate) =>
//      config.setValue(kVersionDate, versionDate);

  Future<String> _getVar(String varName, String metric) async {
    String varValue = config.getValue(varName);
    if (varValue == null) {
      final List<int> charCodes = await fetchUrl(url);
      final Map<String, dynamic> metrics =
      jsonDecode(String.fromCharCodes(charCodes));
      varValue = metrics['scorecard'][metric];
      config.setValue(varName, varValue);
    }
    return varValue;
  }
}
