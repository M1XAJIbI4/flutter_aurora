// SPDX-FileCopyrightText: Copyright 2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../doctor_validator.dart';

/// String extensions
extension ExtString on String {
  String format([Map<String, String>? args]) {
    String result = this;
    if (args != null) {
      for (final MapEntry<String, String> element in args.entries) {
        result = result.replaceAll('{${element.key}}', element.value);
      }
    }
    return result;
  }

  /// String to message error
  ValidationMessage toError() {
    return ValidationMessage.error(this);
  }

  /// String to message array errors
  List<ValidationMessage> toErrors() {
    if (isEmpty) {
      return <ValidationMessage>[];
    }
    return <ValidationMessage>[toError()];
  }

  /// String to message array success
  List<ValidationMessage> toSuccess() {
    if (isEmpty) {
      return <ValidationMessage>[];
    }
    return <ValidationMessage>[ValidationMessage.hint(this)];
  }

  /// String to validate result
  ValidationResult toValidationResult({
    ValidationType type = ValidationType.missing,
  }) {
    return ValidationResult(
      type,
      type == ValidationType.success ? toSuccess() : toErrors(),
    );
  }
}
