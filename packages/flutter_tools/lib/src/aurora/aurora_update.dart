// SPDX-FileCopyrightText: Copyright 2023-2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../version.dart';

/// Latest version of Flutter without update.
const String FRAMEWORK_VERSION_BLOCK = '3.16.2-1';

class AuroraUpdateCommand extends FlutterCommand {
  AuroraUpdateCommand({
    bool isDowngrade = false,
  }) : _isDowngrade = isDowngrade;

  final bool _isDowngrade;

  FlutterVersion get _flutterVersion => globals.flutterVersion;

  @override
  String get description => 'Downgrade Flutter to the last active version for the current channel.';

  @override
  String get name => _isDowngrade ? 'downgrade' : 'upgrade';

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  Future<FlutterCommandResult> runCommand() async {
    await fetchTags();
    final String? tag;
    if (_isDowngrade) {
      tag = await getDowngradeTag();
    } else {
      tag = await getUpgradeTag();
    }
    if (tag == null || tag == FRAMEWORK_VERSION_BLOCK) {
      globals.printStatus('\nYou have the latest version with the ability update.\n');
      globals.printStatus(_flutterVersion.toString());
    } else {
      await checkout(tag);
      await clearCache();
      await updateCacheTools();
    }
    return FlutterCommandResult.success();
  }

  // Update local tags
  Future<void> fetchTags() async {
    globals.printStatus('Update local versions...');
    await globals.processUtils.run(
      <String>['git', 'fetch', '--tags'],
    );
  }

  // Get upgrade tag if exist
  Future<String?> getUpgradeTag() async {
    // Get local tags
    final RunResult result = await globals.processUtils.run(
      <String>['git', 'tag', '--sort=-creatordate'],
    );
    final List<String> list = result.stdout.split('\n');
    final int index = list.indexOf(_flutterVersion.frameworkVersion);
    return index <= 0 ? null : list[index - 1];
  }

  // Get downgrade tag if exist
  Future<String?> getDowngradeTag() async {
    // Get local tags
    final RunResult result = await globals.processUtils.run(
      <String>['git', 'tag', '--sort=-creatordate'],
    );
    final List<String> list = result.stdout.split('\n');
    final int index = list.indexOf(_flutterVersion.frameworkVersion);
    return list.length <= index + 1 ? null : list[index + 1];
  }

  // Update local tags
  Future<void> checkout(String tag) async {
    globals.printStatus('Update version to $tag...');
    try {
      await globals.processUtils.run(
        <String>['git', 'checkout', tag],
      );
    } on ProcessException catch (error) {
      throwToolExit('Error: $error');
    }
  }

  // Clear local cache
  Future<void> clearCache() async {
    final Directory cacheDirectory = globals.fs.directory(globals.fs.path.join(Cache.flutterRoot!, 'bin', 'cache'));
    final Directory toolsDirectory =
        globals.fs.directory(globals.fs.path.join(Cache.flutterRoot!, 'packages', 'flutter_tools', '.dart_tool'));
    await cacheDirectory.delete(recursive: true);
    await toolsDirectory.delete(recursive: true);
  }

  // Update cache tools
  Future<void> updateCacheTools() async {
    globals.printStatus('Update cache and build tools...');
    final RunResult result = await globals.processUtils.run(<String>[
      globals.fs.path.join('bin', 'flutter'),
      '--version',
    ]);
    if (result.exitCode != 0) {
      throwToolExit(null, exitCode: result.exitCode);
    } else {
      globals.printStatus('\nThe update Flutter SDK successful.\n');
      globals.printStatus(result.stdout.trim().split('\n').reversed.take(4).toList().reversed.join('\n'));
    }
  }
}
