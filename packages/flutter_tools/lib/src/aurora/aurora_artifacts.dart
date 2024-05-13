// SPDX-FileCopyrightText: Copyright 2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:convert';

import '../base/file_system.dart';
import '../base/os.dart' show OperatingSystemUtils;
import '../base/platform.dart';
import '../base/process.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import 'aurora_constants.dart';

/// A cached artifact Aurora Flutter-Embedder
class AuroraEmbedder extends CachedArtifact {
  AuroraEmbedder(Cache cache)
      : super(
          'aurora_embedder',
          cache,
          DevelopmentArtifact.universal,
        );

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    final String? latestVersion = await _getLatestVersion();
    if (latestVersion == null) {
      return globals.printWarning('Url aurora_embedder not found...');
    }
    return artifactUpdater.downloadZipArchive(
      'Downloading aurora_embedder tools...',
      _toStorageUri(latestVersion),
      location,
    );
  }

  Uri _toStorageUri(String latestVersion) {
    return Uri.parse(
      'https://gitlab.com/omprussia/flutter/flutter-embedder/-/archive/$latestVersion/flutter-embedder-$latestVersion.zip',
    );
  }

  Future<String?> _getLatestVersion() async {
    final String majorVersion =
        FRAMEWORK_VERSION.split('-').firstOrNull ?? FRAMEWORK_VERSION;
    final RunResult rawTags = await globals.processUtils.run(
      <String>[
        'curl',
        '--silent',
        '--fail',
        'https://gitlab.com/api/v4/projects/53351457/repository/tags?per_page=50&order_by=version&search=$majorVersion*'
      ],
    );
    if (rawTags.exitCode == 22) {
      return null;
    }
    final dynamic tag =
        (json.decode(rawTags.toString()) as List<dynamic>).firstOrNull;
    if (tag == null) {
      return null;
    }
    return (tag as Map<String, dynamic>)['name'].toString();
  }

  static Future<String?> getLatestVersionCache() async {
    return '';
  }

  static Future<String?> getEmbedderFolder() async {
    return '';
  }
}

/// Artifacts required for desktop Aurora builds.
class AuroraEngineArtifacts extends EngineCachedArtifact {
  AuroraEngineArtifacts(Cache cache, {required Platform platform})
      : _platform = platform,
        super(
          'aurora-sdk',
          cache,
          DevelopmentArtifact.aurora,
        );

  final Platform _platform;

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (_platform.isLinux || ignorePlatformFiltering) {
      return <List<String>>[
        <String>[
          'aurora',
          'https://gitlab.com/omprussia/flutter/flutter-engine/-/archive/$FRAMEWORK_VERSION/flutter-engine-$FRAMEWORK_VERSION.zip'
        ],
      ];
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}
