#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🧪 Preparing Quickshell Test Environment..."

TEMP_CONFIG=$(mktemp -d -t qs_notch_test_XXXXXX)
trap "rm -rf '$TEMP_CONFIG'" EXIT

# Symlink components, modules, core, and Config into temp runner config
ln -sf "$DIR/Config.qml" "$TEMP_CONFIG/"
ln -sf "$DIR/qmldir" "$TEMP_CONFIG/"
ln -sf "$DIR/components" "$TEMP_CONFIG/"
ln -sf "$DIR/modules" "$TEMP_CONFIG/"
ln -sf "$DIR/core" "$TEMP_CONFIG/"
cp "$DIR/tests/test_suite.qml" "$TEMP_CONFIG/shell.qml"

rm -f /tmp/notch_test_result

export XDG_RUNTIME_DIR=/tmp
export QT_QPA_PLATFORM=offscreen

echo "🚀 Executing test suite via quickshell..."
quickshell -p "$TEMP_CONFIG/shell.qml" 2>&1 | grep -E "DEBUG qml:|ERROR qml:|PASSED|FAILED|Starting|Running" || true

if [ -f /tmp/notch_test_result ] && [ "$(cat /tmp/notch_test_result)" = "PASSED" ]; then
    echo "🎉 ALL TESTS PASSED!"
    rm -f /tmp/notch_test_result
    exit 0
else
    echo "❌ SOME TESTS FAILED!"
    rm -f /tmp/notch_test_result
    exit 1
fi
