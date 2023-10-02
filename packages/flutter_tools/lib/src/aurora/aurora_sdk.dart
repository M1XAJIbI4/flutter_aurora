// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import '../globals.dart' as globals;

Future<String?> psdkChrootToolPath() async {
  final String? psdkDirectory = Platform.environment['PSDK_DIR'];
  final String? homeDirectory = Platform.environment['HOME'];

  if (psdkDirectory != null) {
    final String chrootTool = globals.fs.path.join(psdkDirectory, 'sdk-chroot');

    if (await globals.fs.file(chrootTool).exists()) {
      return chrootTool;
    }
  }

  if (homeDirectory != null) {
    final String chrootTool = globals.fs.path.join(homeDirectory, 'AuroraPlatformSDK',
        'sdks', 'aurora_psdk', 'sdk-chroot');

    if (await globals.fs.file(chrootTool).exists()) {
      return chrootTool;
    }
  }

  return null;
}
