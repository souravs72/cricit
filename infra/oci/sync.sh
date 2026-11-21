#!/usr/bin/env bash
# DEPRECATED: Use infra/oci/deploy.sh instead.
# Strictly syncs via GitHub commit -> push -> server pull. No rsync.
exec "$(dirname "$0")/deploy.sh" "$@"
