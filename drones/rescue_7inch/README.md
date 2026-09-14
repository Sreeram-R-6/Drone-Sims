# Isolated TBS Source One V5 7-inch rescue drone

This stack is independent of the legacy Iris and earlier `rescue_7inch`
development artifact. It targets a TBS Source One V5 7-inch deadcat frame.

## Physical target

- 1.5 kg AUW, including the 300 g battery
- 4 × 2807 1350 KV motors
- 4 × 7×4 propellers
- Zeus 50 A 4-in-1 ESC
- 4S 5000 mAh 10C battery
- iFlight BLITZ Mini F745 architecture: ICM42688, DPS310, BZ251 GPS, QMC5883 compass
- Raspberry Pi with downward camera only

The Source One V5 7-inch wheelbase is represented as a 320 mm diagonal
assumption. Verify against the physical frame before using this as measured
aircraft data. Motor thrust coefficients remain first-pass simulation values
until measured data is available.

## Contents

```text
config/       vehicle parameters
models/       self-contained vehicle model
world/        disaster terrain, obstacles, target, wind
start/        vehicle-specific bridge and launcher
```

The default world starts calm while the physical wind system is loaded. Wind
profiles should be tested in this order: calm, 5 m/s, 5 m/s with gusts, then
10 m/s. The existing Iris stack is not changed by this package.

## Ports

| Function | Port |
|---|---:|
| Gazebo JSON | 9003 |
| QGroundControl MAVLink | 14560 |
| MAVROS MAVLink | 14561 |

## Launch

```bash
cd ~/drone_project
drones/rescue_7inch/start/start_sim.sh
```

The launcher currently starts Gazebo and ArduCopter only. MAVROS, camera
bridge, QR, and mission processes remain separate validation stages.
