#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# Script to tear down the virtual factory environment
#
# Usage:
#   ./dev_tools/teardown_virtual_factory.sh
#
# Make sure:
#   - You are inside the DevContainer environment (for access to openfactory-sdk)
# -----------------------------------------------------------------------------

echo "🧹 Tearing down virtual factory..."

echo "🗑️ Removing OpenFactory devices..."
for workcenter_dir in dev_tools/virtual_factory/*/; do
  workcenter=$(basename "$workcenter_dir")
  echo "Removing workcenter: $workcenter"
  ofa device down "$workcenter_dir"
done

echo "✅ Virtual factory has been torn down."
