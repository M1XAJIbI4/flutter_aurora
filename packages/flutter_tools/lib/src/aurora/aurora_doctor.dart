// SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../doctor_validator.dart';
import 'aurora_constants.dart';
import 'aurora_sdk.dart';

/// A validator that checks for Clang and Make build dependencies.
class AuroraDoctorValidator extends DoctorValidator {
  AuroraDoctorValidator() : super('Aurora toolchain - develop for Aurora OS');

  @override
  Future<ValidationResult> validate() async {
    /// Get environment variable PSDK_DIR
    final String? psdkDir = getEnvironmentPSDK();
    if (psdkDir == null) {
      return ERROR_PSDK_DIR.toValidationResult();
    }

    /// Get path PSDK chroot tools
    final String? psdkTools = await getEnvironmentPSDKTool();
    if (psdkTools == null) {
      return ERROR_PSDK_TOOL.toValidationResult();
    }

    /// Get version PSDK
    final String? psdkVersion = await getPsdkVersion(psdkTools);
    if (psdkVersion == null) {
      return ERROR_PSDK_VERSION.toValidationResult();
    }

    /// Get available target names
    final List<String>? psdkTargetsName = await getPsdkTargetsName(psdkTools);
    if (psdkTargetsName == null) {
      return ERROR_PSDK_TARGETS.toValidationResult();
    }

    /// Check available architectures
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final List<String> psdkTargetsArch = getPsdkArchNames(psdkVersion);

    for (final String arch in psdkTargetsArch) {
      if (psdkTargetsName
          .where((String e) => e.contains('-$arch'))
          .toList()
          .isEmpty) {
        messages.add(ERROR_PSDK_TARGET.format(<String, String>{
          'arch': arch,
        }).toError());
      }
    }
    if (messages.isNotEmpty) {
      return ValidationResult(ValidationType.missing, messages);
    }

    /// Output success
    return ''.toValidationResult(type: ValidationType.success);
  }
}
