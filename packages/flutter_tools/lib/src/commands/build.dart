// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../commands/build_linux.dart';
import '../commands/build_macos.dart';
import '../commands/build_windows.dart';
import '../runner/flutter_command.dart';
import 'build_aar.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_aurora.dart';
import 'build_bundle.dart';
import 'build_ios.dart';
import 'build_ios_framework.dart';
import 'build_macos_framework.dart';
import 'build_web.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({
    required FileSystem fileSystem,
    required BuildSystem buildSystem,
    required OperatingSystemUtils osUtils,
    required Logger logger,
    required AndroidSdk? androidSdk,
    bool verboseHelp = false,
  }){
    _addSubcommand(
        BuildAarCommand(
          fileSystem: fileSystem,
          androidSdk: androidSdk,
          logger: logger,
          verboseHelp: verboseHelp,
        )
    );
    _addSubcommand(BuildApkCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSFrameworkCommand(
      logger: logger,
      buildSystem: buildSystem,
      verboseHelp: verboseHelp,
    ));
    _addSubcommand(BuildMacOSFrameworkCommand(
      logger: logger,
      buildSystem: buildSystem,
      verboseHelp: verboseHelp,
    ));
    _addSubcommand(BuildIOSArchiveCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildWebCommand(
      fileSystem: fileSystem,
      logger: logger,
      verboseHelp: verboseHelp,
    ));
    _addSubcommand(BuildMacosCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildLinuxCommand(
      logger: logger,
      operatingSystemUtils: osUtils,
      verboseHelp: verboseHelp
    ));
    _addSubcommand(BuildAuroraCommand(
      logger: logger,
      operatingSystemUtils: osUtils,
      verboseHelp: verboseHelp
    ));
    _addSubcommand(BuildWindowsCommand(logger: logger, verboseHelp: verboseHelp));
  }

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  @override
  final String name = 'build';

  @override
  final String description = 'Build an executable app or install bundle.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required Logger logger,
    required bool verboseHelp
  }): _logger = logger {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  final Logger _logger;

  @override
  bool get reportNullSafety => true;

  bool get supported => true;

  /// Display a message describing the current null safety runtime mode
  /// that was selected.
  ///
  /// This is similar to the run message in run_hot.dart
  @protected
  void displayNullSafetyMode(BuildInfo buildInfo) {
    if (buildInfo.nullSafetyMode != NullSafetyMode.sound) {
      _logger.printStatus('');
      _logger.printStatus(
        'Building without sound null safety ⚠️',
        emphasis: true,
      );
      _logger.printStatus(
        'Dart 3 will only support sound null safety, see https://dart.dev/null-safety',
      );
    }
    _logger.printStatus('');
  }
}
