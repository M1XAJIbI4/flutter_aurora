// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:io' as io;

import '../artifacts.dart';
import '../asset.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../bundle_builder.dart';
import '../convert.dart';
import '../devfs.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'aurora_sdk.dart';

File codeSizeFileForArch(BuildInfo buildInfo, String arch) {
  return globals.fs.directory(buildInfo.codeSizeDirectory).childFile('snapshot.$arch.json');
}

File precompilerTraceFileForArch(BuildInfo buildInfo, String arch) {
  return globals.fs.directory(buildInfo.codeSizeDirectory).childFile('trace.$arch.json');
}

Directory getBuildBundleDirectory(TargetPlatform targetPlatform, BuildInfo buildInfo) {
  return globals.fs.directory(getAuroraBuildDirectory(targetPlatform, buildInfo))
                   .childDirectory('bundle');
}

Directory getBuildBundleLibDirectory(TargetPlatform targetPlatform, BuildInfo buildInfo) {
  return getBuildBundleDirectory(targetPlatform, buildInfo).childDirectory('lib');
}

Future<void> buildAurora(
  AuroraProject auroraProject,
  TargetPlatform targetPlatform,
  String target,
  BuildInfo buildInfo, {
    SizeAnalyzer? sizeAnalyzer,
  }) async {
  if (!auroraProject.cmakeFile.existsSync()) {
    throwToolExit('No Aurora OS project configured.');
  }

  createPluginSymlinks(auroraProject.parent);

  final Status status = globals.logger.startProgress('Building Aurora application...');

  try {
    await _timedBuildStep('aurora-recreate-build-dir',
      () => _recreateBuildDir(auroraProject, targetPlatform, buildInfo));

    await _timedBuildStep('aurora-build-assets',
      () => _buildAssets(auroraProject, targetPlatform, buildInfo, target));

    if (buildInfo.mode != BuildMode.debug) {
      await _timedBuildStep('aurora-build-kernel',
        () => _buildKernel(auroraProject, targetPlatform, buildInfo, target));

      await _timedBuildStep('aurora-build-snapshot',
        () => _buildSnapshot(auroraProject, targetPlatform, buildInfo));
    }

    await _timedBuildStep('aurora-copy-engine',
      () => _copyEngine(auroraProject, buildInfo, targetPlatform));

    await _timedBuildStep('aurora-copy-icu',
      () => _copyIcudtl(auroraProject, buildInfo, targetPlatform));

    await _timedBuildStep('aurora-build-rpm',
      () => _buildRPM(auroraProject.cmakeFile.parent, targetPlatform, buildInfo));
  } finally {
    status.cancel();
  }

  if (buildInfo.codeSizeDirectory != null && sizeAnalyzer != null) {
    final String arch = getNameForTargetPlatform(targetPlatform);

    final Map<String, Object?> output = await sizeAnalyzer.analyzeAotSnapshot(
      aotSnapshot: codeSizeFileForArch(buildInfo, arch),
      outputDirectory: getBuildBundleDirectory(targetPlatform, buildInfo),
      precompilerTrace: precompilerTraceFileForArch(buildInfo, arch),
      type: 'linux',
    );

    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs
        .directory(globals.fsUtils.homeDirPath)
        .childDirectory('.flutter-devtools'), 'aurora-code-size-analysis', 'json',
    )..writeAsStringSync(jsonEncode(output));

    globals.printStatus(
      'A summary of your Linux bundle analysis can be found at: ${outputFile.path}',
    );

    final String relativeAppSizePath = outputFile.path.split('.flutter-devtools/').last.trim();
    globals.printStatus(
      '\nTo analyze your app size in Dart DevTools, run the following command:\n'
      'flutter pub global activate devtools; flutter pub global run devtools '
      '--appSizeBase=$relativeAppSizePath'
    );
  }

  final Directory rpmsDir = globals.fs.directory(getAuroraBuildDirectory(targetPlatform, buildInfo))
                                      .childDirectory('RPMS');

  final String rpms = await rpmsDir
      .list()
      .where((FileSystemEntity element) => element.basename.endsWith('.rpm'))
      .map((FileSystemEntity e) => e.absolute.path)
      .join('\n');

  globals.logger.printBox(rpms, title: 'Result');
}

Future<void> _timedBuildStep(String name, Future<void> Function() action) async {
  final Stopwatch sw = Stopwatch()..start();
  await action();
  globals.printTrace('$name: ${sw.elapsedMilliseconds} ms.');
  globals.flutterUsage.sendTiming('build', name, Duration(milliseconds: sw.elapsedMilliseconds));
}

Future<void> _recreateBuildDir(
  AuroraProject auroraProject,
  TargetPlatform targetPlatform,
  BuildInfo buildInfo
) async {
  final Directory buildDirectory = globals.fs.directory(getAuroraBuildDirectory(targetPlatform, buildInfo));
  final Directory bundleLibDirectory = buildDirectory.childDirectory('bundle').childDirectory('lib');

  if (await buildDirectory.exists()) {
    await buildDirectory.delete(recursive: true);
  }

  await bundleLibDirectory.create(recursive: true);
}

Future<void> _buildAssets(
  AuroraProject auroraProject,
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
  String target
) async {
  final String assetsDirPath = getBuildBundleDirectory(targetPlatform, buildInfo).childDirectory('flutter_assets').path;
  final FlutterProject flutterProject = FlutterProject.current();

  if (buildInfo.mode == BuildMode.debug) {
    final BundleBuilder builder = BundleBuilder();
    final String depfilePath = globals.fs.path.join(getAuroraBuildDirectory(targetPlatform, buildInfo), 'snapshot_blob.bin.d');

    await builder.build(platform: targetPlatform,
                        buildInfo: buildInfo,
                        mainPath: target,
                        project: flutterProject,
                        depfilePath: depfilePath,
                        assetDirPath: assetsDirPath);
  } else {
    final AssetBundle? assets = await buildAssets(
      manifestPath: flutterProject.pubspecFile.path,
      packagesPath: flutterProject.packagesFile.path,
      assetDirPath: assetsDirPath,
    );

    if (assets == null) {
      throwToolExit('Unable to find assets.', exitCode: 1);
    }

    final Map<String, DevFSContent> assetEntries = Map<String, DevFSContent>.of(
      assets.entries,
    );

    await writeBundle(globals.fs.directory(assetsDirPath), assetEntries, assets.entryKinds);
  }
}

Future<void> _buildKernel(
  AuroraProject auroraProject,
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
  String target
) async {
    final String? engineDartBinaryPath = globals.artifacts?.getHostArtifact(HostArtifact.engineDartBinary).path;
    final String? frontendSnapshotPath = globals.artifacts?.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);
    final String? patchedSdkProductPath = globals.artifacts?.getArtifactPath(Artifact.flutterPatchedSdkPath);

    if (engineDartBinaryPath == null) {
      throwToolExit('Engine dart binary not found');
    }

    if (frontendSnapshotPath == null) {
      throwToolExit('Engine frontend snapshot not found');
    }

    if (patchedSdkProductPath == null) {
      throwToolExit('Flutter patched sdk product not found');
    }

    final FlutterProject flutterProject = FlutterProject.current();
    final String packagesConfigFile = flutterProject.packageConfigFile.path;
    final String fsRoot = flutterProject.directory.path;
    final String relativePackagesConfigFile = globals.fs.path.relative(packagesConfigFile, from: fsRoot);
    final String buildDir = getAuroraBuildDirectory(targetPlatform, buildInfo);
    final String outDillPath = globals.fs.path.join(buildDir, 'app.dill');
    final String depfilePath = globals.fs.path.join(buildDir, 'kernel_snapshot.d');

    final int result = await globals.processUtils.stream(
      <String>[
        engineDartBinaryPath,
        '--disable-dart-dev',
        frontendSnapshotPath,
        '--sdk-root', patchedSdkProductPath,
        '--target', 'flutter',
        '-Ddart.vm.profile=false',
        '-Ddart.vm.product=true',
        '--aot', '--tfa',
        '--packages', relativePackagesConfigFile,
        '--output-dill', outDillPath,
        '--depfile', depfilePath,
        target
      ],
      trace: true,
      workingDirectory: flutterProject.directory.path
    );

    if (result != 0) {
      throwToolExit('Build process failed');
    }
}

Future<void> _buildSnapshot(
  AuroraProject auroraProject,
  TargetPlatform targetPlatform,
  BuildInfo buildInfo,
) async {
  final String? genSnapshot = globals.artifacts?.getArtifactPath(
    Artifact.genSnapshot,
    platform: targetPlatform,
    mode: buildInfo.mode
  );

  if (genSnapshot == null) {
    throwToolExit('Gensnapshot utility not found');
  }

  final String arch = getNameForTargetPlatform(targetPlatform);
  final String dillPath = globals.fs.path.join(getAuroraBuildDirectory(targetPlatform, buildInfo), 'app.dill');
  final Directory bundleLibDir = getBuildBundleLibDirectory(targetPlatform, buildInfo);
  final String elf = globals.fs.path.join(bundleLibDir.path, 'libapp.so');

  final int result = await globals.processUtils.stream(<String>[
      genSnapshot,
      '--deterministic',
      '--snapshot_kind=app-aot-elf',
      '--elf=$elf',
      '--strip',
      if (buildInfo.dartObfuscation) '--obfuscate',
      if (buildInfo.codeSizeDirectory != null)
        '--write-v8-snapshot-profile-to=${codeSizeFileForArch(buildInfo, arch).path}',
      if (buildInfo.codeSizeDirectory != null)
        '--trace-precompiler-to=${precompilerTraceFileForArch(buildInfo, arch).path}',
      dillPath,
    ],
    trace: true,
  );

  if (result != 0) {
    throwToolExit('Build process failed');
  }
}

Future<void> _copyEngine(
  AuroraProject auroraProject,
  BuildInfo buildInfo,
  TargetPlatform targetPlatform,
) async {
  final String? flutterEngineSoPath = globals.artifacts?.getArtifactPath(
    Artifact.auroraFlutterEngineSoPath,
    platform: targetPlatform,
    mode: buildInfo.mode,
  );

  if (flutterEngineSoPath == null) {
    throwToolExit('Flutter engine shared library not found');
  }

  final Directory bundleLibDir = getBuildBundleLibDirectory(targetPlatform, buildInfo);
  final File sourceFlutterEngineSo = globals.fs.file(flutterEngineSoPath);
  final File destFlutterEngineSo = bundleLibDir.childFile(sourceFlutterEngineSo.basename);

  await sourceFlutterEngineSo.copy(destFlutterEngineSo.path);
}

Future<void> _copyIcudtl(
  AuroraProject auroraProject,
  BuildInfo buildInfo,
  TargetPlatform targetPlatform,
) async {
  final String? icudtlPath = globals.artifacts?.getArtifactPath(
    Artifact.icuData,
    platform: targetPlatform,
    mode: buildInfo.mode,
  );

  if (icudtlPath == null) {
    throwToolExit('icudtl.dat not found');
  }

  final Directory bundleDir = getBuildBundleDirectory(targetPlatform, buildInfo);
  final File sourceIcudtl = globals.fs.file(icudtlPath);
  final File destIcudtl = bundleDir.childFile(sourceIcudtl.basename);

  await sourceIcudtl.copy(destIcudtl.path);
}

Future<void> _buildRPM(
  Directory sourceDir,
  TargetPlatform targetPlatform,
  BuildInfo buildInfo
) async {
  final String? psdkToolPath = await psdkChrootToolPath();

  if (psdkToolPath == null) {
    throwToolExit(globals.userMessages.psdkMissing);
  }

  if (!globals.processManager.canRun(psdkToolPath)) {
    throwToolExit(globals.userMessages.psdkMissing);
  }

  final int result = await globals.processUtils.stream(
    <String>[
      psdkToolPath,
      'mb2',
      'build',
      if (buildInfo.mode == BuildMode.debug) '-d',
      sourceDir.path,
      '--',
      '--define',
      if (buildInfo.mode == BuildMode.debug) '_flutter_build_type Debug',
      if (buildInfo.mode != BuildMode.debug) '_flutter_build_type Release',
    ],
    workingDirectory: getAuroraBuildDirectory(targetPlatform, buildInfo),
    trace: true,
  );

  if (result != 0) {
    throwToolExit('Unable to generate build files');
  }
}
