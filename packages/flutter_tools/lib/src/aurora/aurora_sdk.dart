// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:io';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../globals.dart' as globals;

// @todo not in upstream
/// Version Flutter SDK
const String FRAMEWORK_VERSION = '3.16.2-1';

/// Engine downloads url
const String ENGINE_URL =
    'https://gitlab.com/omprussia/flutter/flutter-engine/-/raw/{tag}/engines/{psdk}/{engine}/{file}';

/// Engine tags url
const String ENGINE_TAGS =
    'https://gitlab.com/api/v4/projects/53055476/repository/tags?per_page=50&order_by=version&search={search}*';

/// Path psdk
String? _psdkDir;
String? _psdkVersion;

/// Init PSDK data
Future<bool> initPsdk(String psdkDir) async {
  /// Init _psdkDir
  final String chrootTool = globals.fs.path.join(psdkDir, 'sdk-chroot');

  if (await globals.fs.file(chrootTool).exists()) {
    _psdkDir = psdkDir;
  } else {
    return false;
  }

  /// Init _psdkVersion
  final RunResult result = await globals.processUtils.run(
    <String>[
      chrootTool,
      'version',
    ],
  );

  _psdkVersion = const LineSplitter()
      .convert(result.stdout)
      .toList()
      .lastOrNull
      ?.split(' ')
      .elementAt(1);

  return _psdkDir != null && _psdkVersion != null;
}

/// Is init psdk
void checkInitPsdk() {
  if (_psdkDir == null ||
      _psdkVersion == null ||
      !globals.processManager
          .canRun(globals.fs.path.join(_psdkDir!, 'sdk-chroot'))) {
    throwToolExit('An error occurred while initializing the psdk.');
  }
}

/// Get path psdk
String getPsdkChrootToolPath() {
  checkInitPsdk();
  return globals.fs.path.join(_psdkDir!, 'sdk-chroot');
}

/// Get version psdk
String getPsdkVersion() {
  checkInitPsdk();
  return _psdkVersion!;
}

/// Get major version psdk
String getPsdkMajorKeyVersion() {
  return 'psdk_${_psdkVersion!.substring(0, 1)}';
}

/// Get name psdk target by target platform
String getPsdkArchName(TargetPlatform targetPlatform) {
  if (targetPlatform == TargetPlatform.aurora_arm) {
    return 'armv7hl';
  } else if (targetPlatform == TargetPlatform.aurora_arm64) {
    return 'aarch64';
  } else if (targetPlatform == TargetPlatform.aurora_x64) {
    return 'x86_64';
  }
  throwToolExit('Target ${targetPlatform.name} not found.');
}

/// Get target psdk name
Future<String?> getPsdkTargetName(TargetPlatform targetPlatform) async {
  final String psdkToolPath = getPsdkChrootToolPath();
  final String psdkTarget = getPsdkArchName(targetPlatform);

  final RunResult result = await globals.processUtils.run(
    <String>[
      psdkToolPath,
      'sb2-config',
      '-f',
    ],
  );

  final List<String> psdkTargets = const LineSplitter()
      .convert(result.stdout)
      .where((String e) =>
          e.contains('AuroraOS') &&
          e.contains(psdkTarget) &&
          !e.contains('default'))
      .toList();

  return psdkTargets.firstOrNull;
}

/// Check exist engine
Future<bool> checkEngine(
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
) async {
  final String? engineBinaryPath = globals.artifacts?.getArtifactPath(
      Artifact.auroraFlutterEngineSoPath,
      platform: targetPlatform,
      mode: buildInfo.mode
  );

  if (engineBinaryPath == null) {
    return false;
  }

  /// Download if not exist
  if (!await globals.fs.file(engineBinaryPath).exists()) {
    return downloadEngine(targetPlatform, buildInfo);
  }

  return true;
}

/// Download engine
Future<bool> downloadEngine(
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
) async {
  final String arch = getNameForTargetPlatform(targetPlatform);
  final String psdkMajorKeyVersion = getPsdkMajorKeyVersion();
  final String buildMode = getNameForBuildMode(buildInfo.mode);
  final String suffix = buildMode != BuildMode.debug.name ? '-$buildMode' : '';
  final String? engineBinaryPath = globals.artifacts?.getArtifactPath(
      Artifact.auroraFlutterEngineSoPath,
      platform: targetPlatform
  );
  final Directory engineFolder = Directory(
      '${engineBinaryPath!.replaceAll('/libflutter_engine.so', '')}$suffix');

  await engineFolder.create(recursive: true);

  globals.printStatus('Download aurora "$arch ($buildMode)" engine...');

  /// Get latest version tag
  final RunResult rawTags = await globals.processUtils.run(
    <String>[
      'curl',
      '--silent',
      '--fail',
      ENGINE_TAGS.replaceAll('{search}', FRAMEWORK_VERSION.split('-').first)
    ],
  );

  if (rawTags.exitCode == 22) {
    return false;
  }

  final dynamic tag = (json.decode(rawTags.toString()) as List<dynamic>).firstOrNull;

  if (tag == null) {
    return false;
  }

  /// Files
  final List<String> files = <String>[
    'gen_snapshot',
    'icudtl.dat',
    'libflutter_engine.so',
  ];

  /// Downloads files
  for (final String file in files) {
    final RunResult result = await globals.processUtils.run(
      <String>[
        'curl',
        '--silent',
        '--fail',
        ENGINE_URL
            .replaceAll('{tag}', (tag as Map<String, dynamic>)['name'].toString())
            .replaceAll('{psdk}', psdkMajorKeyVersion)
            .replaceAll('{engine}', '$arch$suffix')
            .replaceAll('{file}', file),
        '--output',
        '${engineFolder.path}/$file'
      ],
    );
    if (result.exitCode == 22) {
      await engineFolder.delete(recursive: true);
      return false;
    }
  }

  /// Make snapshot executable
  await globals.processUtils.run(
    <String>['chmod', '+x', '${engineFolder.path}/gen_snapshot'],
  );

  return true;
}
