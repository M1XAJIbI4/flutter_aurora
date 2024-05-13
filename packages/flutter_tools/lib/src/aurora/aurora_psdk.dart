// SPDX-FileCopyrightText: Copyright 2023-2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:io';

import '../base/common.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import 'aurora_constants.dart';

class AuroraPSDK {
  AuroraPSDK._(this._tool);

  final String _tool;
  static String? _version;

  static Future<AuroraPSDK> fromEnv() async {
    final String? env = Platform.environment['PSDK_DIR'];
    if (env == null) {
      throw Exception(ERROR_PSDK_DIR);
    }
    final String tool = '$env/sdk-chroot';
    if (!await globals.fs.file(tool).exists()) {
      throw Exception(ERROR_PSDK_TOOL);
    }
    final AuroraPSDK psdk = AuroraPSDK._(tool);
    // init static version
    _version ??= await psdk.getVersion();
    // result
    return psdk;
  }

  static Future<AuroraPSDK> fromPath(String psdkDir) async {
    final String tool = '$psdkDir/sdk-chroot';
    if (!await globals.fs.file(tool).exists()) {
      throw Exception(ERROR_PSDK_TOOL);
    }
    final AuroraPSDK psdk = AuroraPSDK._(tool);
    // init static version
    _version ??= await psdk.getVersion();
    // result
    return psdk;
  }

  static String getStaticVersion() {
    if (_version == null) {
      throwToolExit(
        'The PSDK has not been initialized. An error occurred while retrieving the version.',
      );
    }
    return _version!;
  }

  static String getStaticVersionMajor() {
    if (_version == null) {
      throwToolExit(
        'The PSDK has not been initialized. An error occurred while retrieving the version.',
      );
    }
    return _version!.substring(0, 1);
  }

  static String getStaticEnginePath() {
    if (_version == null) {
      throwToolExit(
        'The PSDK has not been initialized. An error occurred while retrieving the version.',
      );
    }
    return _version!.substring(0, 1);
  }

  Future<String?> getVersion() async {
    final RunResult result = await globals.processUtils.run(
      <String>[
        _tool,
        'version',
      ],
    );
    return const LineSplitter()
        .convert(result.stdout)
        .toList()
        .lastOrNull
        ?.split(' ')
        .elementAt(1);
  }

  Future<List<String>?> getListTargets() async {
    final RunResult result = await globals.processUtils.run(
      <String>[
        _tool,
        'sb2-config',
        '-f',
      ],
    );
    return const LineSplitter().convert(result.stdout);
  }

  Future<String?> findTargetName(TargetPlatform targetPlatform) async {
    final List<String>? targetsNames = await getListTargets();
    if (targetsNames == null) {
      return null;
    }

    final String? arch = _getArchMap()?[targetPlatform];
    if (arch == null) {
      return null;
    }

    final List<String> psdkTargets = targetsNames
        .where((String e) =>
            e.contains('Aurora') && e.contains(arch) && !e.contains('default'))
        .toList();

    return psdkTargets.firstOrNull;
  }

  Future<bool> buildRPM(
    String path,
    BuildInfo buildInfo,
    TargetPlatform targetPlatform,
  ) async {
    final String version = getStaticVersion();
    final String versionMajor = getStaticVersionMajor();
    final String? targetName = await findTargetName(targetPlatform);

    if (targetName == null) {
      return false;
    }

    final RunResult result = await globals.processUtils.run(
      <String>[
        _tool,
        'mb2',
        '--target',
        targetName,
        '--no-fix-version',
        'build',
        if (buildInfo.mode == BuildMode.debug) '-d',
        path,
        '--',
        '--define',
        '_flutter_psdk_version $version',
        '--define',
        '_flutter_psdk_major ${int.parse(versionMajor)}',
        '--define',
        if (buildInfo.mode == BuildMode.debug) '_flutter_build_type Debug',
        if (buildInfo.mode != BuildMode.debug) '_flutter_build_type Release',
      ],
    );
    return result.exitCode != 0;
  }

  Future<bool> installEmbedder() async {
    return true;
  }

  Future<String?> getVersionEmbedder(String target) async {
    final RunResult result = await globals.processUtils.run(
      <String>[
        _tool,
        'sb2',
        '-t',
        target,
        '-R',
        'zypper',
        '--disable-repositories',
        'search',
        '--installed-only',
        '-s',
        'flutter',
      ],
    );
    return result.stdout
        .split('\n')
        .where((String e) => e.contains('flutter-embedder-devel'))
        .firstOrNull
        ?.split('|')[3]
        .trim();
  }

  List<TargetPlatform>? getArchPlatforms() {
    return _getArchMap()?.keys.toList();
  }

  List<String>? getArchNames() {
    return _getArchMap()?.values.toList();
  }

  Map<TargetPlatform, String>? _getArchMap() {
    if (getStaticVersionMajor() == '5') {
      return ARCHITECTURES_5;
    }
    return ARCHITECTURES_4;
  }
}
