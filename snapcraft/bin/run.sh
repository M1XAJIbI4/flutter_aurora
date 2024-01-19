#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2024 Open Mobile Platform LLC <community@omp.ru>
# SPDX-License-Identifier: BSD-3-Clause

## Check flutter exist
if [ ! -f "$SNAP_USER_COMMON/bin/flutter" ]; then
  ## Clone flutter
  git clone https://gitlab.com/omprussia/flutter/flutter.git "$SNAP_USER_COMMON"
  ## Checkout to tag if exist
  if [ -n "$FLUTTER_TAG" ]; then
    cd "$SNAP_USER_COMMON" || exit
    git checkout "$FLUTTER_TAG" --quiet
  fi
fi

## Run flutter
"$SNAP_USER_COMMON"/bin/flutter "$@"
