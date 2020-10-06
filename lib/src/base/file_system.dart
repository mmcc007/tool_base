// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';

import 'common.dart' show throwToolExit;
import 'context.dart';
import 'platform.dart';
import 'process.dart';

export 'package:file/file.dart';
export 'package:file/local.dart';

const String _kRecordingType = 'file';
const FileSystem _kLocalFs = LocalFileSystem();

/// Currently active implementation of the file system.
///
/// By default it uses local disk-based implementation. Override this in tests
/// with [MemoryFileSystem].
FileSystem get fs => context.get<FileSystem>() ?? _kLocalFs;

/// Create the ancestor directories of a file path if they do not already exist.
void ensureDirectoryExists(String filePath) {
  final String dirPath = fs.path.dirname(filePath);
  if (fs.isDirectorySync(dirPath))
    return;
  try {
    fs.directory(dirPath).createSync(recursive: true);
  } on FileSystemException catch (e) {
    throwToolExit('Failed to create directory "$dirPath": ${e.osError.message}');
  }
}

/// Recursively copies `srcDir` to `destDir`, invoking [onFileCopied] if
/// specified for each source/destination file pair.
///
/// Creates `destDir` if needed.
void copyDirectorySync(Directory srcDir, Directory destDir, [ void onFileCopied(File srcFile, File destFile) ]) {
  if (!srcDir.existsSync())
    throw Exception('Source directory "${srcDir.path}" does not exist, nothing to copy');

  if (!destDir.existsSync())
    destDir.createSync(recursive: true);

  for (FileSystemEntity entity in srcDir.listSync()) {
    final String newPath = destDir.fileSystem.path.join(destDir.path, entity.basename);
    if (entity is File) {
      final File newFile = destDir.fileSystem.file(newPath);
      newFile.writeAsBytesSync(entity.readAsBytesSync());
      onFileCopied?.call(entity, newFile);
    } else if (entity is Directory) {
      copyDirectorySync(
        entity, destDir.fileSystem.directory(newPath));
    } else {
      throw Exception('${entity.path} is neither File nor Directory');
    }
  }
}

/// Gets a directory to act as a recording destination, creating the directory
/// as necessary.
///
/// The directory will exist in the local file system, be named [basename], and
/// be a child of the directory identified by [dirname].
///
/// If the target directory already exists as a directory, the existing
/// directory must be empty, or a [ToolExit] will be thrown. If the target
/// directory exists as an entity other than a directory, a [ToolExit] will
/// also be thrown.
Directory getRecordingSink(String dirname, String basename) {
  final String location = _kLocalFs.path.join(dirname, basename);
  switch (_kLocalFs.typeSync(location, followLinks: false)) {
    case FileSystemEntityType.file:
    case FileSystemEntityType.link:
      throwToolExit('Invalid record-to location: $dirname ("$basename" exists as non-directory)');
      break;
    case FileSystemEntityType.directory:
      if (_kLocalFs.directory(location).listSync(followLinks: false).isNotEmpty)
        throwToolExit('Invalid record-to location: $dirname ("$basename" is not empty)');
      break;
    case FileSystemEntityType.notFound:
      _kLocalFs.directory(location).createSync(recursive: true);
  }
  return _kLocalFs.directory(location);
}

/// Gets a directory that holds a saved recording to be used for the purpose of
/// replay.
///
/// The directory will exist in the local file system, be named [basename], and
/// be a child of the directory identified by [dirname].
///
/// If the target directory does not exist, a [ToolExit] will be thrown.
Directory getReplaySource(String dirname, String basename) {
  final Directory dir = _kLocalFs.directory(_kLocalFs.path.join(dirname, basename));
  if (!dir.existsSync())
    throwToolExit('Invalid replay-from location: $dirname ("$basename" does not exist)');
  return dir;
}

/// Canonicalizes [path].
///
/// This function implements the behavior of `canonicalize` from
/// `package:path`. However, unlike the original, it does not change the ASCII
/// case of the path. Changing the case can break hot reload in some situations,
/// for an example see: https://github.com/flutter/flutter/issues/9539.
String canonicalizePath(String path) => fs.path.normalize(fs.path.absolute(path));

/// Escapes [path].
///
/// On Windows it replaces all '\' with '\\'. On other platforms, it returns the
/// path unchanged.
String escapePath(String path) => platform.isWindows ? path.replaceAll('\\', '\\\\') : path;

/// Returns true if the file system [entity] has not been modified since the
/// latest modification to [referenceFile].
///
/// Returns true, if [entity] does not exist.
///
/// Returns false, if [entity] exists, but [referenceFile] does not.
bool isOlderThanReference({ @required FileSystemEntity entity, @required File referenceFile }) {
  if (!entity.existsSync())
    return true;
  return referenceFile.existsSync()
      && referenceFile.lastModifiedSync().isAfter(entity.statSync().modified);
}

/// Exception indicating that a file that was expected to exist was not found.
class FileNotFoundException implements IOException {
  const FileNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'File not found: $path';
}
