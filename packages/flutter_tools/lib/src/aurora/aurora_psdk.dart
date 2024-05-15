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
    // check sudo activate
    if (!await psdk.isExistSudo()) {
      throw Exception(ERROR_PSDK_SUDOERS);
    }
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
    return getStaticVersion().substring(0, 1);
  }

  Future<bool> isExistSudo() async {
    // Check settings sudoers

    // final isExistSudoers0 = await File('/etc/sudoers.d/sdk-chroot')
    //     .openRead()
    //     .map(utf8.decode)
    //     .transform(const LineSplitter()).toList();
    //
    // globals.printStatus('--------------------------');
    // globals.printStatus(isExistSudoers0.firstWhere((String line) => line.contains(_tool)));
    // globals.printStatus('--------------------------');

    final String line = (await File('/etc/sudoers.d/sdk-chroot')
            .openRead()
            .map(utf8.decode)
            .transform(const LineSplitter())
            .toList())
        .firstWhere((String line) => line.contains(_tool), orElse: () => '');

    if (line.isNotEmpty) {
      return true;
    }

    // Check sudo caches credentials
    final RunResult result = await globals.processUtils.run(
      <String>[
        'sudo',
        '-S',
        'true',
      ],
    );

    if (result.exitCode == 0) {
      return true;
    }

    return false;
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

  Future<void> buildRPM(
    String path,
    BuildInfo buildInfo,
    TargetPlatform targetPlatform,
  ) async {
    final String version = getStaticVersion();
    final String versionMajor = getStaticVersionMajor();
    final String? targetName = await findTargetName(targetPlatform);

    if (targetName == null) {
      throwToolExit('Not found target PSDK');
    }

    final int result = await globals.processUtils.stream(
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
      workingDirectory: getAuroraBuildDirectory(targetPlatform, buildInfo),
      treatStderrAsStdout: true,
    );

    if (result != 0) {
      throwToolExit('Unable to generate build files');
    }
  }

  Future<bool> checkEmbedder(
    TargetPlatform targetPlatform,
  ) async {
    // Get folder embedder RPM
    final Directory? embedderArtifact = await getPathEmbedder(targetPlatform);
    if (embedderArtifact == null) {
      return false;
    }
    // Get PSDK target name
    final String? targetName = await findTargetName(targetPlatform);
    if (targetName == null) {
      return false;
    }
    // Get version install embedder
    final String? installVersion = await getVersionEmbedder(targetName);
    // Get list rpm packages
    final List<FileSystemEntity> rpms = await embedderArtifact.list().toList();
    // Get version folder embedder
    final String folderVersion = globals.fs.path
        .basename(rpms.first.path)
        .replaceAll('.${_getArchMap()?[targetPlatform]}.rpm', '')
        .replaceAll('flutter-embedder-', '')
        .replaceAll('devel-', '');

    // Install embedder
    if (installVersion == null ||
        folderVersion != installVersion && !installVersion.contains('-dev')) {
      globals.printStatus(
        '${installVersion == null ? 'Install' : 'Reinstall'} flutter embedder to target "$targetName"...',
      );
      await removeEmbedder(targetName);
      final List<String> packages =
          rpms.map((FileSystemEntity e) => e.path).toList();
      packages.sort();
      for (final String path in packages) {
        if (!await installToTargetRPM(targetName, path)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<Directory?> getPathEmbedder(
    TargetPlatform targetPlatform,
  ) async {
    final String? arch = _getArchMap()?[targetPlatform];

    if (arch == null) {
      return null;
    }

    final Directory pathEmbedders = Directory(globals.fs.path.join(
      globals.cache.getCacheArtifacts().path,
      'aurora_embedder',
    ));

    final List<String> folder = (await pathEmbedders.list().toList())
        .map((FileSystemEntity entity) => globals.fs.path.basename(entity.path))
        .toList();

    return Directory(globals.fs.path.join(
      globals.cache.getCacheArtifacts().path,
      'aurora_embedder',
      folder.first,
      'embedder',
      'psdk_${AuroraPSDK.getStaticVersionMajor()}',
      arch,
    ));
  }

  Future<bool> installToTargetRPM(String targetName, String pathRPM) async {
    final RunResult result = await globals.processUtils.run(
      <String>[
        _tool,
        'sb2',
        '-t',
        targetName,
        '-m',
        'sdk-install',
        '-R',
        'zypper',
        '--no-gpg-checks',
        'in',
        '-y',
        pathRPM,
      ],
    );
    return result.exitCode == 0;
  }

  Future<bool> removeEmbedder(String targetName) async {
    final RunResult result = await globals.processUtils.run(
      <String>[
        _tool,
        'sb2',
        '-t',
        targetName,
        '-m',
        'sdk-install',
        '-R',
        'zypper',
        'rm',
        '-y',
        'flutter-embedder',
      ],
    );
    return result.exitCode == 0;
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
    return getStaticVersionMajor() == '5' ? ARCHITECTURES_5 : ARCHITECTURES_4;
  }
}
