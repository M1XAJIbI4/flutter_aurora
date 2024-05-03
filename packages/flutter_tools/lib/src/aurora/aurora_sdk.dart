// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:io';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../doctor_validator.dart';
import '../globals.dart' as globals;
import 'aurora_constants.dart';

/// Path psdk
bool _offline = false;
String? _initPsdkDir;
String? _initPsdkVersion;

/// Init PSDK data
Future<bool> initPsdk(String psdkDir, bool offline) async {
  /// Init _initPsdkDir
  final String chrootTool = globals.fs.path.join(psdkDir, 'sdk-chroot');

  if (await globals.fs.file(chrootTool).exists()) {
    _initPsdkDir = psdkDir;
    _offline = offline;
  } else {
    return false;
  }

  _initPsdkVersion = await getPsdkVersion(chrootTool);

  return _initPsdkDir != null && _initPsdkVersion != null;
}

/// Is init psdk
void checkInitPsdk() {
  if (_initPsdkDir == null ||
      _initPsdkVersion == null ||
      !globals.processManager
          .canRun(globals.fs.path.join(_initPsdkDir!, 'sdk-chroot'))) {
    throwToolExit('An error occurred while initializing the psdk.');
  }
}

/// Get path psdk with check
String getInitPsdkChrootToolPath() {
  checkInitPsdk();
  return globals.fs.path.join(_initPsdkDir!, 'sdk-chroot');
}

/// Get version psdk with check
String getInitPsdkVersion() {
  checkInitPsdk();
  return _initPsdkVersion!;
}

/// Get base psdk folder
String? getEnvironmentPSDK() {
  return Platform.environment['PSDK_DIR'];
}

/// Get base psdk chroot tool
Future<String?> getEnvironmentPSDKTool() async {
  final String toolPath = '${getEnvironmentPSDK()}/sdk-chroot';
  if (await globals.fs.file(toolPath).exists()) {
    return toolPath;
  }
  return null;
}

/// Get major version psdk
String getPsdkMajorKeyVersion() {
  return 'psdk_${_initPsdkVersion!.substring(0, 1)}';
}

/// Get list architectures names
List<String> getPsdkArchNames(String psdkVersion) {
  if (psdkVersion.startsWith('5.')) {
    return ARCHITECTURES_5.values.toList();
  }
  return ARCHITECTURES_4.values.toList();
}

/// Get name psdk target by target platform
String getPsdkArchName(TargetPlatform targetPlatform) {
  if (!ARCHITECTURES_FULL.containsKey(targetPlatform)) {
    throwToolExit('Target ${targetPlatform.name} not found.');
  }
  return ARCHITECTURES_FULL[targetPlatform]!;
}

/// Get query version PSDK
Future<String?> getPsdkVersion(String psdkToolPath) async {
  if (!await globals.fs.file(psdkToolPath).exists()) {
    return null;
  }

  final RunResult result = await globals.processUtils.run(
    <String>[
      psdkToolPath,
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

/// Get list names psdk targets
Future<List<String>?> getPsdkTargetsName(String psdkToolPath) async {
  if (!await globals.fs.file(psdkToolPath).exists()) {
    return null;
  }

  final RunResult result = await globals.processUtils.run(
    <String>[
      psdkToolPath,
      'sb2-config',
      '-f',
    ],
  );

  final List<String> psdkTargets = <String>[];

  for (final String line in const LineSplitter().convert(result.stdout)) {
    if (line.contains('default')) {
      continue;
    }
    if (!line.contains('Aurora')) {
      continue;
    }
    for (final String arch in ARCHITECTURES_FULL.values) {
      if (line.contains('-$arch')) {
        psdkTargets.add(line);
      }
    }
  }

  return psdkTargets.isEmpty ? null : psdkTargets;
}

/// Get target psdk name
Future<String?> getPsdkTargetName(TargetPlatform targetPlatform) async {
  final String psdkToolPath = getInitPsdkChrootToolPath();
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
  final String psdkToolPath = getInitPsdkChrootToolPath();
  final String? target = await getPsdkTargetName(targetPlatform);

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
      '--disable-repositories',
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

  /// In offline not installed
  if (version == null && _offline) {
    return false;
  }

  /// Check if install dev embedder
  if (version != null &&
      (version.contains('+') || version.contains('dev') || _offline)) {
    return true;
  }

  /// Get latest tag for update
  final String? latestVersionEmbedder = await getLatestVersionEmbedder();

  /// Check empty result: if empty - all ok
  if (latestVersionEmbedder == null) {
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
  final String psdkToolPath = getInitPsdkChrootToolPath();
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
    if (_offline) {
      return false;
    }
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

  /// String to message error
  ValidationMessage toError() {
    return ValidationMessage.error(this);
  }

  /// String to message array errors
  List<ValidationMessage> toErrors() {
    if (isEmpty) {
      return <ValidationMessage>[];
    }
    return <ValidationMessage>[toError()];
  }

  /// String to message array success
  List<ValidationMessage> toSuccess() {
    if (isEmpty) {
      return <ValidationMessage>[];
    }
    return <ValidationMessage>[ValidationMessage.hint(this)];
  }

  /// String to validate result
  ValidationResult toValidationResult({
    ValidationType type = ValidationType.missing,
  }) {
    return ValidationResult(
      type,
      type == ValidationType.success ? toSuccess() : toErrors(),
    );
  }
}
