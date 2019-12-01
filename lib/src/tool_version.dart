import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:pub_cache/pub_cache.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/net.dart';
import 'cache.dart';

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

  static ToolVersion get instance => context.get<ToolVersion>();

//  http.Client _client;
  File _file;
  Config _config;

//  http.Client get client => _client ??= http.Client();

  File get file =>
      _file ??= fs.file(fs.path.join(Cache.flutterRoot, settingsPath));

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

  Future<String> getLatestVersion({bool forceRemote = false}) async =>
      await _getVar(kLatestVersion, 'packageVersion', forceRemote);

//  void setVersion(String version) => config.setValue(kVersion, version);

  Future<String> getVersionDate({bool forceRemote = false}) async {
    String versionDate = await _getVar(kVersionDate, 'updated', forceRemote);
    // hack, can't find real date
    if (versionDate == null) {
      versionDate = DateTime.now().toIso8601String();
      config.setValue(kVersionDate, versionDate);
    }
    return versionDate;
  }

//  void setVersionDate(String versionDate) =>
//      config.setValue(kVersionDate, versionDate);

  Future<String> _getVar(
    String varName,
    String metric,
    bool forceRemote,
  ) async {
    if (forceRemote) {
      final List<int> charCodes = await fetchUrl(url);
      final Map<String, dynamic> metrics =
          jsonDecode(String.fromCharCodes(charCodes));
      final String varValue = metrics['scorecard'][metric];
      // save locally ??
      config.setValue(varName, varValue);
      return varValue;
    } else {
      return config.getValue(varName);
    }
  }

  String getInstalledVersion() {
    return PubCache()
        .getGlobalApplications()
        .firstWhere((app) => app.name == packageName, orElse: () => null)
        .version
        .toString();
  }
}
