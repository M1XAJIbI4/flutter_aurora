// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import '../aurora/aurora_sdk.dart';
import '../aurora/build_aurora.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a aurora target through a build shell script.
class BuildAuroraCommand extends BuildSubCommand {
  BuildAuroraCommand({
    required super.logger,
    required OperatingSystemUtils operatingSystemUtils,
    bool verboseHelp = false,
  })  : _operatingSystemUtils = operatingSystemUtils,
        super(verboseHelp: verboseHelp) {
    addBuildModeFlags(verboseHelp: verboseHelp);
    addDartObfuscationOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addSplitDebugInfoOption();
    usesAnalyzeSizeFlag();
    usesDartDefineOption();
    usesPubOption();
    argParser.addOption(
      'target-platform',
      defaultsTo: 'aurora-arm',
      allowed: <String>['aurora-arm', 'aurora-arm64', 'aurora-x64'],
      help: 'The target platform for which the app is compiled.',
    );
    argParser.addOption(
      'psdk-dir',
      defaultsTo: Platform.environment['PSDK_DIR'],
      help: 'You can specify path to Aurora Platform SDK.',
    );
    argParser.addFlag(
      'offline',
      help: 'You can specify path to Aurora Platform SDK.',
      negatable: false,
    );
    usesTargetOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  final OperatingSystemUtils _operatingSystemUtils;

  @override
  final String name = 'aurora';

  @override
  bool get hidden => !featureFlags.isAuroraEnabled || !globals.platform.isLinux;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async =>
      <DevelopmentArtifact>{
        DevelopmentArtifact.aurora,
      };

  @override
  String get description => 'Build a Aurora OS application.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    final TargetPlatform targetPlatform =
        getTargetPlatformForName(stringArg('target-platform')!);
    final String pathPSDK = stringArg('psdk-dir')!;
    final bool offline = boolArg('offline');

    if (!featureFlags.isAuroraEnabled) {
      throwToolExit(
          '"build aurora" is not currently supported. To enable, run "flutter config --enable-aurora".');
    }

    if (!globals.platform.isLinux ||
        _operatingSystemUtils.hostPlatform != HostPlatform.linux_x64) {
      throwToolExit('"build aurora" only supported on Linux x64 hosts.');
    }

    if (!await initPsdk(pathPSDK, offline)) {
      throwToolExit(
          'Platform SDK not found. You specified the wrong path or you do not have export PSDK_DIR.');
    }

    if (await getPsdkTargetName(targetPlatform) == null) {
      throwToolExit(
          'The target for the required architecture was not found in the Platform SDK.');
    }

    if (!await checkEngine(targetPlatform, buildInfo)) {
      throwToolExit("The engine won't find it.");
    }

    if (!await checkEmbedder(targetPlatform, buildInfo)) {
      throwToolExit("The embedder won't find it.");
    }

    displayNullSafetyMode(buildInfo);
    await buildAurora(
      flutterProject.aurora,
      targetPlatform,
      targetFile,
      buildInfo,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: globals.fs,
        logger: globals.logger,
        flutterUsage: globals.flutterUsage,
      ),
    );
    return FlutterCommandResult.success();
  }
}
