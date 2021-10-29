#!/bin/bash

# Run this script to update dependencies before deploying charts from local sources.

set -eo pipefail

cd helx
helm dependency update
cd charts/monitoring
helm dependency update
cd ../image-utils
helm dependency update
cd ../../../
