#!/bin/sh
set -eu

home="$(mktemp -d /tmp/opencode/mempalace-test-home.XXXXXX)"
trap 'rm -rf "$home"' EXIT
HOME="$home" bun test tests/
