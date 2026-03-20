#!/bin/bash
set -e

CONFIG=/home/git/zimbra-build-scripts/config.build

# Apply BUILD_RELEASE_NO if provided
if [ -n "${BUILD_RELEASE_NO:-}" ]; then
    sed -i "s/^BUILD_RELEASE_NO[[:space:]]*=.*/BUILD_RELEASE_NO = ${BUILD_RELEASE_NO}/" "$CONFIG"
fi

# Apply BUILD_RELEASE if provided (anchored to avoid matching BUILD_RELEASE_NO)
if [ -n "${BUILD_RELEASE:-}" ]; then
    sed -i "s/^BUILD_RELEASE[[:space:]]*=.*/BUILD_RELEASE = ${BUILD_RELEASE}/" "$CONFIG"
fi

echo "=== config.build after env override ==="
cat "$CONFIG"
echo "======================================="

exec /home/git/zimbra-build-scripts/zimbra-build-helper.sh --build-zimbra
