#!/usr/bin/env bash

# Publish a time-limited, changing physical wind profile to Gazebo Harmonic.
# Direction is degrees in the Gazebo XY plane: 0=+X, 90=+Y.

set -u

WORLD_NAME="rescue_7inch_disaster"
WIND_TOPIC="/world/${WORLD_NAME}/wind_info"
STRENGTH="${1:-}"
DIRECTION="${2:-}"
DURATION="${3:-}"

if [[ -z "$STRENGTH" || -z "$DIRECTION" || -z "$DURATION" ]]; then
  echo "Usage: $0 STRENGTH_MPS DIRECTION_DEG DURATION_SEC"
  echo "Example: $0 5 90 60"
  exit 2
fi

if ! awk -v s="$STRENGTH" -v d="$DIRECTION" -v t="$DURATION" \
  'BEGIN { exit !(s >= 0 && t > 0 && d == d) }'; then
  echo "Strength must be >= 0, direction must be numeric, duration must be > 0."
  exit 2
fi

publish_wind() {
  local x="$1"
  local y="$2"
  gz topic -t "$WIND_TOPIC" -m gz.msgs.Wind \
    -p "linear_velocity: {x: ${x}, y: ${y}, z: 0}" \
    >/dev/null 2>&1 || true
}

calm() {
  publish_wind 0 0
}

trap calm INT TERM EXIT

echo "Wind topic: $WIND_TOPIC"
echo "Requested: ${STRENGTH} m/s, direction ${DIRECTION} deg, ${DURATION} sec"
echo "Random variation: +/-15% magnitude, +/-10 deg direction"

end_time="$(awk -v d="$DURATION" 'BEGIN { print systime() + d }')"

while awk -v end="$end_time" 'BEGIN { exit !(systime() < end) }'; do
  read -r x y <<EOF
$(awk -v s="$STRENGTH" -v deg="$DIRECTION" 'BEGIN {
  pi=atan2(0,-1); srand();
  mag=s*(0.85 + rand()*0.30);
  angle=(deg + (rand()*20.0 - 10.0))*pi/180.0;
  printf "%.4f %.4f", mag*cos(angle), mag*sin(angle)
}')
EOF
  publish_wind "$x" "$y"
  echo "Wind: x=${x} y=${y} m/s"
  sleep 0.5
done

calm
echo "Wind duration complete; returned to calm."
