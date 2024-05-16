// SPDX-FileCopyrightText: Copyright 2023-2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../doctor_validator.dart';
import 'aurora_constants.dart';
import 'aurora_extensions.dart';
import 'aurora_psdk.dart';

/// A validator that checks for Clang and Make build dependencies.
class AuroraDoctorValidator extends DoctorValidator {
  AuroraDoctorValidator() : super('Aurora toolchain - develop for Aurora OS');

  @override
  Future<ValidationResult> validate() async {
    try {
      final AuroraPSDK psdk = await AuroraPSDK.fromEnv();

      /// Get available target names
      final List<String>? psdkTargetsName = await psdk.getListTargets();
      if (psdkTargetsName == null) {
        return ERROR_PSDK_TARGETS.toValidationResult();
      }

      /// Get available architectures
      final List<String>? psdkTargetsArch = psdk.getArchNames();
      if (psdkTargetsArch == null) {
        return ERROR_PSDK_TOOL.toValidationResult();
      }

      /// Check available architectures
      final List<ValidationMessage> messages = <ValidationMessage>[];
      for (final String arch in psdkTargetsArch) {
        if (psdkTargetsName.where((String e) => e.contains('-$arch')).toList().isEmpty) {
          messages.add(ERROR_PSDK_TARGET.format(<String, String>{
            'arch': arch,
          }).toError());
        }
      }
      if (messages.isNotEmpty) {
        return ValidationResult(ValidationType.missing, messages);
      }
    } on Exception catch (e) {
      return e.toString().toValidationResult();
    }

    /// Output success
    return ''.toValidationResult(type: ValidationType.success);
  }
}
