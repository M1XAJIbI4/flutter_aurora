// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:process/process.dart';
import '../base/user_messages.dart';
import '../doctor_validator.dart';
import 'aurora_sdk.dart';

/// A validator that checks for Clang and Make build dependencies.
class AuroraDoctorValidator extends DoctorValidator {
  AuroraDoctorValidator({
    required ProcessManager processManager,
    required UserMessages userMessages,
  }) : _processManager = processManager,
       _userMessages = userMessages,
       super('Aurora toolchain - develop for Aurora OS');

  final UserMessages _userMessages;
  final ProcessManager _processManager;

  Future<bool> _isFlutterEmbedderInRepos(String psdkToolPath) async {
    ProcessResult? result;

    try {
      result = await _processManager.run(<String>[
        psdkToolPath,
        'sb2',
        'zypper',
        'se',
        'flutter-embedder-devel',
      ]);
    } on ArgumentError {
      // ignore error.
    } on ProcessException {
      // ignore error.
    }

    return result != null && result.exitCode == 0;
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final String? psdkToolPath = await psdkChrootToolPath();

    if (psdkToolPath == null) {
      messages.add(ValidationMessage.error(_userMessages.psdkMissing));
      return ValidationResult(ValidationType.missing, messages);
    }

    if (!await _isFlutterEmbedderInRepos(psdkToolPath)) {
      messages.add(ValidationMessage.error(
        _userMessages.flutterEmbedderNotAvailable));
      return ValidationResult(ValidationType.missing, messages);
    }

    return ValidationResult(ValidationType.installed, messages);
  }
}
