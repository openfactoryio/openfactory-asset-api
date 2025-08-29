#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# Script to deploy the virtual factory environment
#
# Usage:
#   ./dev_tools/deploy_virtual_factory.sh
#
# Make sure:
#   - Kafka and ksqlDB are running (via `spinup`)
#   - You are inside the DevContainer environment (for access to openfactory-sdk)
# -----------------------------------------------------------------------------

echo "🔧 Deploying virtual devices to OpenFactory..."
for workcenter_dir in dev_tools/virtual_factory/*/; do
  workcenter=$(basename "$workcenter_dir")
  echo "Deploying workcenter: $workcenter"
  ofa device up "$workcenter_dir"
done

echo "✅ Virtual factory is now running."
