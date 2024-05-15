// SPDX-FileCopyrightText: Copyright 2023-2024 Open Mobile Platform LLC <community@omp.ru>
// SPDX-License-Identifier: BSD-3-Clause

import '../base/platform.dart';
import '../doctor_validator.dart';
import '../features.dart';

/// The aurora-specific implementation of a [Workflow].
class AuroraWorkflow implements Workflow {
  const AuroraWorkflow({
    required Platform platform,
    required FeatureFlags featureFlags,
  }) : _platform = platform,
       _featureFlags = featureFlags;

  final Platform _platform;
  final FeatureFlags _featureFlags;

  @override
  bool get appliesToHostPlatform => _platform.isLinux && _featureFlags.isAuroraEnabled;

  @override
  bool get canLaunchDevices => false;

  @override
  bool get canListDevices => false;

  @override
  bool get canListEmulators => false;
}
