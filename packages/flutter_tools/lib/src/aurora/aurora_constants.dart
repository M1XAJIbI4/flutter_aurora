// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../build_info.dart';

//////////////////////
// Flutter

// @todo if not upstream
/// Version Flutter SDK
const String FRAMEWORK_VERSION = '3.16.2-2';

//////////////////////
// URLs

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

//////////////////////
// Architectures

/// List architectures available
const Map<TargetPlatform, String> ARCHITECTURES_FULL = <TargetPlatform, String>{
  TargetPlatform.aurora_arm: 'armv7hl',
  TargetPlatform.aurora_arm64: 'aarch64',
  TargetPlatform.aurora_x64: 'x86_64',
};

/// List architectures Aurora 5
const Map<TargetPlatform, String> ARCHITECTURES_5 = ARCHITECTURES_FULL;

/// List architectures Aurora 4
const Map<TargetPlatform, String> ARCHITECTURES_4 = <TargetPlatform, String>{
  TargetPlatform.aurora_arm: 'armv7hl',
};

//////////////////////
// Errors

/// Show error in doctor if not found PSDK_DIR
const String ERROR_PSDK_DIR = '''
Check for the presence of the PSDK_DIR environment variable.
The Platform SDK is required for assembly; more details about the installation can be found here:
https://developer.auroraos.ru/doc/software_development/psdk/setup''';

/// Show error in doctor if not found PSDK chroot tool
const String ERROR_PSDK_TOOL = '''
Failed to access Platform SDK.
The Platform SDK is required for assembly; more details about the installation can be found here:
https://developer.auroraos.ru/doc/software_development/psdk/setup''';

/// Show error in doctor if not found PSDK targets
const String ERROR_PSDK_VERSION = '''
Failed to get Platform SDK version.
The Platform SDK is required for assembly; more details about the installation can be found here:
https://developer.auroraos.ru/doc/software_development/psdk/setup''';

/// Show error in doctor if not found PSDK targets
const String ERROR_PSDK_TARGETS = '''
No targets found in Platform SDK. Check their names, they should match the pattern:
AuroraOS-{version}-base-{architecture}
Platform SDK setup: https://developer.auroraos.ru/doc/software_development/psdk/setup''';

/// Show error in doctor if not found PSDK target
const String ERROR_PSDK_TARGET = '''
Target {arch} is not available.''';
