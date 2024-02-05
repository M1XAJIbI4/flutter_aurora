// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:io';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../globals.dart' as globals;

// @todo if not upstream
/// Version Flutter SDK
const String FRAMEWORK_VERSION = '3.16.2-1';

/// Engine downloads url
const String ENGINE_URL =
    'https://gitlab.com/omprussia/flutter/flutter-engine/-/raw/{tag}/engines/{psdk}/{engine}/{file}';

/// Engine tags url
const String ENGINE_TAGS =
    'https://gitlab.com/api/v4/projects/53055476/repository/tags?per_page=50&order_by=version&search={search}*';

/// Embedder downloads url
const String EMBEDDER_URL =
    'https://gitlab.com/omprussia/flutter/flutter-embedder/-/archive/{tag}/flutter-embedder-{tag}.zip';

/// Embedder tags url
const String EMBEDDER_TAGS =
    'https://gitlab.com/api/v4/projects/53351457/repository/tags?per_page=50&order_by=version&search={search}*';

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
          e.contains('Aurora') &&
          e.contains(psdkTarget) &&
          !e.contains('default'))
      .toList();

  return psdkTargets.firstOrNull;
}

/// Check embedder update or not exist
Future<bool> checkEmbedder(
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
) async {
  final String psdkToolPath = getPsdkChrootToolPath();
  final String? target = await getPsdkTargetName(targetPlatform);
  final String? latestVersionEmbedder = await getLatestVersionEmbedder();

  if (latestVersionEmbedder == null) {
    return true;
  }

  if (target == null) {
    return false;
  }

  final RunResult result = await globals.processUtils.run(
    <String>[
      psdkToolPath,
      'sb2',
      '-t',
      target,
      '-R',
      'zypper',
      'search',
      '--installed-only',
      '-s',
      'flutter',
    ],
  );

  final String? version = result.stdout
      .split('\n')
      .where((String e) => e.contains('flutter-embedder-devel'))
      .firstOrNull
      ?.split('|')[3]
      .trim();

  /// Check if install dev embedder
  if (version != null && version.contains('+')) {
    return true;
  }

  /// Install if not found embedder
  if (version == null) {
    return installEmbedder(targetPlatform, latestVersionEmbedder);
  }

  /// Install if has new version embedder
  final String tagVersion = '${FRAMEWORK_VERSION.split('-').first}-$version';
  if (tagVersion != latestVersionEmbedder) {
    return installEmbedder(targetPlatform, latestVersionEmbedder);
  }

  return result.exitCode == 0;
}

/// Get latest embedder flutter sdk version
Future<String?> getLatestVersionEmbedder() async {
  /// Get latest version tag
  final RunResult rawTags = await globals.processUtils.run(
    <String>[
      'curl',
      '--silent',
      '--fail',
      EMBEDDER_TAGS.format(<String, String>{
        'search': FRAMEWORK_VERSION.split('-').first,
      })
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

  final String latestVersionTag =
      (tag as Map<String, dynamic>)['name'].toString();

  return latestVersionTag;
}

/// Download embedder
Future<bool> downloadEmbedder(
  String tag,
) async {
  final Directory embeddersFolder = Directory(
      globals.fs.path.join(globals.cache.getRoot().path, 'embedder', tag));

  /// Check if not exist embedder
  if (!await globals.fs.directory(embeddersFolder.path).exists()) {
    globals.printStatus('Downloading aurora embedder "$tag"...');

    final File archive = File(
        globals.fs.path.join(embeddersFolder.path, 'flutter-embedder.zip'));
    final Directory archiveFolder = Directory(
        globals.fs.path.join(embeddersFolder.path, 'flutter-embedder-$tag'));

    await embeddersFolder.create(recursive: true);

    /// Download embedder
    final RunResult download = await globals.processUtils.run(
      <String>[
        'curl',
        '--silent',
        '--fail',
        EMBEDDER_URL.format(<String, String>{'tag': tag}),
        '--output',
        archive.path
      ],
    );

    if (download.exitCode != 0) {
      await embeddersFolder.delete(recursive: true);
      return false;
    }

    /// Unpack zip embedder
    final RunResult unpack = await globals.processUtils.run(
      <String>[
        'unzip',
        archive.path,
        '-d',
        embeddersFolder.path,
      ],
    );

    if (unpack.exitCode != 0) {
      await embeddersFolder.delete(recursive: true);
      return false;
    }

    /// Move embedders rpm
    final Directory psdk_5 = Directory(
        globals.fs.path.join(archiveFolder.path, 'embedder', 'psdk_5'));
    final Directory psdk_4 = Directory(
        globals.fs.path.join(archiveFolder.path, 'embedder', 'psdk_4'));

    if (await globals.fs.directory(psdk_5.path).exists() &&
        await globals.fs.directory(psdk_4.path).exists()) {
      await psdk_5.rename('${embeddersFolder.path}/psdk_5');
      await psdk_4.rename('${embeddersFolder.path}/psdk_4');
    } else {
      await embeddersFolder.delete(recursive: true);
      return false;
    }

    /// Remove cache download
    await archive.delete();
    await archiveFolder.delete(recursive: true);
  }

  return true;
}

/// Install embedder
Future<bool> installEmbedder(
  TargetPlatform targetPlatform,
  String tag,
) async {
  /// Download if not exist
  if (!await downloadEmbedder(tag)) {
    return false;
  }

  final String psdkTarget = getPsdkArchName(targetPlatform);
  final String psdkMajorKeyVersion = getPsdkMajorKeyVersion();
  final String psdkToolPath = getPsdkChrootToolPath();
  final String? target = await getPsdkTargetName(targetPlatform);

  final Directory embedderFolder = Directory(globals.fs.path.join(
      globals.cache.getRoot().path,
      'embedder',
      tag,
      psdkMajorKeyVersion,
      psdkTarget));

  if (target == null) {
    return false;
  }

  globals.printStatus('Installing aurora embedder "$tag"...');

  await globals.processUtils.run(
    <String>[
      psdkToolPath,
      'sb2',
      '-t',
      target,
      '-m',
      'sdk-install',
      '-R',
      'zypper',
      'rm',
      '-y',
      'flutter-embedder',
    ],
  );

  final List<String> packages = (await embedderFolder.list().toList())
      .map((FileSystemEntity e) => e.path)
      .toList();

  packages.sort();

  for (final String path in packages) {
    final RunResult install = await globals.processUtils.run(
      <String>[
        psdkToolPath,
        'sb2',
        '-t',
        target,
        '-m',
        'sdk-install',
        '-R',
        'zypper',
        '--no-gpg-checks',
        'in',
        '-y',
        path,
      ],
    );

    if (install.exitCode != 0) {
      globals.printStatus('Error: ${install.stdout}\n${install.stderr}');
      return false;
    }
  }

  return true;
}

/// Check exist engine
Future<bool> checkEngine(
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
) async {
  final String? engineBinaryPath = globals.artifacts?.getArtifactPath(
    Artifact.auroraFlutterEngineSoPath,
    platform: targetPlatform,
    mode: buildInfo.mode,
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
    platform: targetPlatform,
  );
  final Directory engineFolder = Directory(
      '${engineBinaryPath!.replaceAll('/libflutter_engine.so', '')}$suffix');

  await engineFolder.create(recursive: true);

  globals.printStatus('Downloading aurora "$arch ($buildMode)" engine...');

  /// Get latest version tag
  final RunResult rawTags = await globals.processUtils.run(
    <String>[
      'curl',
      '--silent',
      '--fail',
      ENGINE_TAGS.format(<String, String>{
        'search': FRAMEWORK_VERSION.split('-').first,
      })
    ],
  );

  if (rawTags.exitCode == 22) {
    return false;
  }

  final dynamic tag =
      (json.decode(rawTags.toString()) as List<dynamic>).firstOrNull;

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
        ENGINE_URL.format(<String, String>{
          'tag': (tag as Map<String, dynamic>)['name'].toString(),
          'psdk': psdkMajorKeyVersion,
          'engine': '$arch$suffix',
          'file': file,
        }),
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

  ENGINE_URL.format();

  return true;
}

/// String extensions
extension ExtString on String {
  String format([Map<String, String>? args]) {
    String result = this;
    if (args != null) {
      for (final MapEntry<String, String> element in args.entries) {
        result = result.replaceAll('{${element.key}}', element.value);
      }
    }
    return result;
  }
}
