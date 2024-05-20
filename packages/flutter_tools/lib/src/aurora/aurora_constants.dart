// SPDX-FileCopyrightText: Copyright 2023-2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../build_info.dart';

//////////////////////
// Flutter

// @todo if not upstream
/// Version Flutter SDK
const String FRAMEWORK_VERSION = '3.16.2-2';

//////////////////////
// Architectures

/// List architectures Aurora 4
const Map<TargetPlatform, String> ARCHITECTURES_4 = <TargetPlatform, String>{
  TargetPlatform.aurora_arm: 'armv7hl',
};

/// List architectures Aurora 5
const Map<TargetPlatform, String> ARCHITECTURES_5 = <TargetPlatform, String>{
  TargetPlatform.aurora_arm: 'armv7hl',
  TargetPlatform.aurora_arm64: 'aarch64',
  TargetPlatform.aurora_x64: 'x86_64',
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
const String ERROR_PSDK_TARGETS = '''
No targets found in Platform SDK. Check their names, they should match the pattern:
AuroraOS-{version}-base-{architecture}
Platform SDK setup: https://developer.auroraos.ru/doc/software_development/psdk/setup''';

/// Show error in doctor if not found sdk-chroot sudoers fix
const String ERROR_PSDK_SUDOERS = r'''
Executing the command requires root access.
Update your sudoers settings using the template:

Update file /etc/sudoers.d/mer-sdk-chroot:

$USER ALL=(ALL) NOPASSWD: $PSDK_DIR
Defaults!$PSDK_DIR env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"

Update file /etc/sudoers.d/sdk-chroot:

$USER ALL=(ALL) NOPASSWD: $PSDK_DIR/sdk-chroot
Defaults!$PSDK_DIR/sdk-chroot env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"

Alternatively, enter the `sudo` command before executing the Flutter CLI command.''';

/// Show error in doctor if not found PSDK target
const String ERROR_PSDK_TARGET = '''
Target {arch} is not available.''';
