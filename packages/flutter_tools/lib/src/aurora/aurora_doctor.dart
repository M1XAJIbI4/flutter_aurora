// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import '../base/user_messages.dart';
import '../doctor_validator.dart';
import '../globals.dart' as globals;

/// A validator that checks for Clang and Make build dependencies.
class AuroraDoctorValidator extends DoctorValidator {
  AuroraDoctorValidator({
    required ProcessManager processManager,
    required UserMessages userMessages,
  })  : _processManager = processManager,
        _userMessages = userMessages,
        super('Aurora toolchain - develop for Aurora OS');

  final UserMessages _userMessages;
  final ProcessManager _processManager;

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final String psdkTools = '${Platform.environment['PSDK_DIR']}/sdk-chroot';
    final String psdkTarget =
        '${Platform.environment['PSDK_DIR']}/../../targets';

    /// Check exist psdk
    if (!await globals.fs.file(psdkTools).exists()) {
      messages.add(const ValidationMessage.error(
          'Platfrom SDK is required for Aurora development.\n'
          'Platform SDK setup: https://developer.auroraos.ru/doc/software_development/psdk/setup\n'
          'You may not have set the PSDK_DIR environment variable.'));
      return ValidationResult(ValidationType.missing, messages);
    }

    return ValidationResult(ValidationType.success, messages);
  }
}
