#!/usr/bin/env bash

# Independent Kitty launcher for the rescue_7inch stack.
# Cleanup is deliberately scoped to this drone's world, ports, and commands.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DRONE_DIR="$PROJECT_DIR/drones/rescue_7inch"
SESSION="$DRONE_DIR/start/rescue_7inch.kitty-session"

stop_matching() { command pkill -TERM -f -- "$1" 2>/dev/null || true; }
force_stop_matching() { command pkill -KILL -f -- "$1" 2>/dev/null || true; }

cleanup_existing() {
  echo "Stopping existing rescue_7inch processes..."
  for pattern in \
    "$DRONE_DIR/world/rescue_7inch.sdf" \
    '/home/user/ardupilot/build/sitl/bin/arducopter.*--sim-port-out=9003' \
    'mavproxy.py.*14560' \
    'mavros_node.*14561' \
    'parameter_bridge.*rescue_7inch' \
    'python3.*drone_project/vision/camera_view.py' \
    'python3.*qr_gcs_receiver.py' \
    'ros2 run rescue_control (qr_detector|geotag_mission)'; do
    stop_matching "$pattern"
  done
  sleep 2
  for pattern in \
    "$DRONE_DIR/world/rescue_7inch.sdf" \
    '/home/user/ardupilot/build/sitl/bin/arducopter.*--sim-port-out=9003' \
    'mavproxy.py.*14560' \
    'mavros_node.*14561' \
    'parameter_bridge.*rescue_7inch' \
    'python3.*drone_project/vision/camera_view.py' \
    'python3.*qr_gcs_receiver.py' \
    'ros2 run rescue_control (qr_detector|geotag_mission)'; do
    force_stop_matching "$pattern"
  done
}

cleanup_existing

export GZ_VERSION=harmonic
export GZ_SIM_RESOURCE_PATH="$DRONE_DIR/models:$DRONE_DIR/world/models:$PROJECT_DIR/models:$HOME/gz_ws/src/ardupilot_gazebo/models:$DRONE_DIR/world"
export GZ_SIM_SYSTEM_PLUGIN_PATH="$HOME/gz_ws/src/ardupilot_gazebo/build:$HOME/gz_ws/src/ardupilot_gazebo/build/lib:${GZ_SIM_SYSTEM_PLUGIN_PATH:-}"

echo "======================================"
echo " STARTING RESCUE 7-INCH SIM"
echo "======================================"
echo "World: $DRONE_DIR/world/rescue_7inch.sdf"
echo "JSON:  127.0.0.1:9003"
echo "MAVLink: 14560 QGC / 14561 MAVROS"

cat > "$SESSION" <<SESSION_EOF
new_tab
title Gazebo
cd ~
launch --type=os-window --title="Rescue 7-inch Gazebo" bash -lc 'source /opt/ros/humble/setup.bash; export GZ_VERSION=harmonic; export GZ_SIM_RESOURCE_PATH="$DRONE_DIR/models:$DRONE_DIR/world/models:$PROJECT_DIR/models:$HOME/gz_ws/src/ardupilot_gazebo/models:$DRONE_DIR/world"; export GZ_SIM_SYSTEM_PLUGIN_PATH="$HOME/gz_ws/src/ardupilot_gazebo/build:$HOME/gz_ws/src/ardupilot_gazebo/build/lib:\${GZ_SIM_SYSTEM_PLUGIN_PATH:-}"; gz sim -v4 -r "$DRONE_DIR/world/rescue_7inch.sdf"; exec bash'

new_tab
title ArduCopter SITL
cd ~
launch --type=os-window --title="Rescue 7-inch ArduCopter" bash -lc 'sleep 3; "$HOME/ardupilot/build/sitl/bin/arducopter" --model JSON:127.0.0.1 --speedup 1 --sim-port-out=9003 --defaults "$DRONE_DIR/config/rescue_7inch.parm" --sim-address=127.0.0.1 -I0; exec bash'

new_tab
title MAVProxy
cd ~
launch --type=os-window --title="Rescue 7-inch MAVProxy" bash -lc 'sleep 8; mavproxy.py --retries 5 --master tcp:127.0.0.1:5760 --sitl 127.0.0.1:5501 --out 127.0.0.1:14560 --out 127.0.0.1:14561; exec bash'

new_tab
title MAVROS
cd ~
launch --type=os-window --title="Rescue 7-inch MAVROS" bash -lc 'sleep 10; source /opt/ros/humble/setup.bash; ros2 run mavros mavros_node --ros-args -p fcu_url:=udp://127.0.0.1:14561@; exec bash'

new_tab
title Camera Bridge
cd ~
launch --type=os-window --title="Rescue 7-inch Camera Bridge" bash -lc 'sleep 10; source /opt/ros/humble/setup.bash; ros2 run ros_gz_bridge parameter_bridge --ros-args -p config_file:="$DRONE_DIR/start/camera_bridge.yaml"; exec bash'

new_tab
title Camera View
cd ~
launch --type=os-window --title="Rescue 7-inch Camera" bash -lc 'sleep 12; source /opt/ros/humble/setup.bash; python3 "$PROJECT_DIR/vision/camera_view.py"; exec bash'

new_tab
title GCS
cd ~
launch --type=os-window --title="Rescue 7-inch GCS" bash -lc 'python3 "$HOME/qr_gcs_receiver.py"; exec bash'

new_tab
title Mission
cd ~
launch --type=os-window --title="Rescue 7-inch Mission" bash -lc 'sleep 14; source /opt/ros/humble/setup.bash; source "$PROJECT_DIR/ros2_ws/install/setup.bash"; ros2 run rescue_control qr_detector & ros2 run rescue_control geotag_mission; exec bash'
SESSION_EOF

chmod +x "$SESSION"
echo "Kitty session: $SESSION"
kitty --session "$SESSION"
