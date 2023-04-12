// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    required OperatingSystemUtils operatingSystemUtils,
    bool verboseHelp = false,
  }) : _operatingSystemUtils = operatingSystemUtils,
       super(verboseHelp: verboseHelp) {
    addBuildModeFlags(verboseHelp: verboseHelp);
    addDartObfuscationOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addSplitDebugInfoOption();
    usesAnalyzeSizeFlag();
    usesDartDefineOption();
    usesPubOption();
    usesTargetOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  final OperatingSystemUtils _operatingSystemUtils;

  @override
  final String name = 'aurora';

  @override
  bool get hidden => !featureFlags.isAuroraEnabled || !globals.platform.isLinux;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.aurora,
  };

  @override
  String get description => 'Build a Aurora OS application.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();

    if (!featureFlags.isAuroraEnabled) {
      throwToolExit('"build aurora" is not currently supported. To enable, run "flutter config --enable-aurora".');
    }
    if (!globals.platform.isLinux || _operatingSystemUtils.hostPlatform != HostPlatform.linux_x64) {
      throwToolExit('"build aurora" only supported on Linux x64 hosts.');
    }

    displayNullSafetyMode(buildInfo);
    await buildAurora(
      flutterProject.aurora,
      TargetPlatform.aurora_arm,
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
