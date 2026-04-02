#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_SCRIPT="$SCRIPT_DIR/scripts/protocol-cli.ts"

show_help() {
  cat << 'HELP'
Protocol Guard
=============

Usage: router.sh <command> [args]

Commands:
  interactive-health         Check question UI + decision-gate readiness
  compact-health             Check compact protocol integrity
  compact-readiness [phase]  Evaluate GO/HOLD for phase2 or phase3
  all                        Run all checks
  help                       Show this help

Examples:
  ./router.sh interactive-health
  ./router.sh compact-health
  ./router.sh compact-readiness phase2
  ./router.sh all
HELP
}

if [ ! -f "$CLI_SCRIPT" ]; then
  echo "Error: protocol-cli.ts not found at $CLI_SCRIPT"
  exit 1
fi

if [ $# -eq 0 ] || [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

cd "$SCRIPT_DIR"
TS_NODE_COMPILER_OPTIONS='{"module":"commonjs"}' npx ts-node "$CLI_SCRIPT" "$@"
