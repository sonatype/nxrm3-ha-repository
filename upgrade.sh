#!/bin/sh
#
# Sonatype Nexus (TM) Open Source Version
# Copyright (c) 2008-present Sonatype, Inc.
# All rights reserved. Includes the third-party code listed at http://links.sonatype.com/products/nexus/oss/attributions.
#
# This program and the accompanying materials are made available under the terms of the Eclipse Public License Version 1.0,
# which accompanies this distribution and is available at http://www.eclipse.org/legal/epl-v10.html.
#
# Sonatype Nexus (TM) Professional Version is available from Sonatype, Inc. "Sonatype" and "Sonatype Nexus" are trademarks
# of Sonatype, Inc. Apache Maven is a trademark of the Apache Software Foundation. M2eclipse is a trademark of the
# Eclipse Foundation. All other trademarks are the property of their respective owners.
#

if [ $# != 3 ]; then
    echo "Usage: $0 <dir> <chart-version> <app-version>"
    exit 1
fi

DIR="$1"
CHART_VERSION="$2"
APP_VERSION="$3"

OUTPUT_FILE=$(mktemp)

cat "$DIR/Chart.yaml" \
  | sed -E "s/version: .+/version: $CHART_VERSION/" \
  | sed -E "s/appVersion: .+/appVersion: $APP_VERSION/" \
  > "$OUTPUT_FILE"

mv "$OUTPUT_FILE" "$DIR/Chart.yaml"

cat "$DIR/values.yaml" \
  | sed -E "s/^  tag: .+$/  tag: $APP_VERSION/" \
  > "$OUTPUT_FILE"

mv "$OUTPUT_FILE" "$DIR/values.yaml"

git diff "$DIR"
