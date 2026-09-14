#!/usr/bin/env bash

# Independent rescue_7inch launcher. Existing Iris and legacy launchers are untouched.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DRONE_DIR="$PROJECT_DIR/drones/rescue_7inch"
export GZ_VERSION=harmonic
export GZ_SIM_RESOURCE_PATH="$DRONE_DIR/models:$DRONE_DIR/world/models:$PROJECT_DIR/models:$HOME/gz_ws/src/ardupilot_gazebo/models:$DRONE_DIR/world"
export GZ_SIM_SYSTEM_PLUGIN_PATH="$HOME/gz_ws/src/ardupilot_gazebo/build:$HOME/gz_ws/src/ardupilot_gazebo/build/lib:${GZ_SIM_SYSTEM_PLUGIN_PATH:-}"

echo "Launching isolated rescue_7inch simulation"
echo "World: $DRONE_DIR/world/rescue_7inch.sdf"
echo "JSON: 127.0.0.1:9003"

gz sim -v4 -r "$DRONE_DIR/world/rescue_7inch.sdf" &
GZ_PID=$!

cleanup() {
  kill "$GZ_PID" 2>/dev/null || true
  wait "$GZ_PID" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

sleep 3
cd "$HOME/ardupilot"
./Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON:127.0.0.1:9003 --console --map --out=127.0.0.1:14560 --out=127.0.0.1:14561
