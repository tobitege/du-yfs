# YFS Changelog

All notable changes to this project will be documented in this file.

## 0.0.12 - 2023-04-02

### NOTE
* Requires new screen-code when updating to, or past, this version.

### Changed
* Slight improvement to WASD control in terms of holding position and stopping.
* Reduced engine flicker while maintaining speed in atmosphere (practically only noticeable on tiny ships)
* Improved serialization of data to screen for reduced resource usage.
* ECU now properly shuts down if floor is detected.

### Added
* New commands: `route-move-pos-back` and `route-move-pos-forward`
* Now supports running on an ECU.

## 0.0.11 - 2023-04-01

### Fixed
* Waypoint no longer set when controlling with WSAD.

## 0.0.10 - 2023-04-01

### Added
* Support for setting limits on engine type, size and count. This is to allow selling smaller, purpose built, ships without giving away the entire script for a reduced price.

### Fixed
* Made correction to properly read boolean 'false' from settings.
* Changes to WSAD controller for more reliable key press captures.

### Changed
* Changes to WSAD controller for faster stop.

## 0.0.9 - 2023-03-26

### Changed

* Fixed PID selection for axis control relating to lighter constructs.
* Manual control (WASD, Alt-A/D) controls no longer moves by steps and instead accelerates as longs as the key is held.
* Manual control speed now controlled via mouse scroll wheel.
* `goto` now takes and `offset` option so that it is possible to stop at an offset from the given point. Negative offsets means the other side of the point from where the approach happens.

### Added
* A tiny hud showing target speed and max speed in upper left corner of the screen.
* New setting `-throttleStep` to control step size for manual control
* New setting `-manualControlOnStartup` to make the controller enable manual control on startup.

### Removed
* `speed` command

### Fixed

* `strafe` command no longer turns towards the new position

## 0.0.8 - 2023-03-12

### Changed

* Threshold for triggering precision movement for a path increased to 0.95.
* Path alignment now only checked when moving along a precision path; this makes diagonal movement more smooth (at the cost of less accuracy during the acceleration phase)
* Adjusted low speed control to be a bit more responsive.
* Adjusted roll/yaw/pitch controls to reduce overshoot.

## 0.0.7 - 2023-03-11

### Changed

* Refactored alignment functions.

## 0.0.6 - 2023-03-09

### Changed

* Route data bank is now expected to be named "Routes"

### Added

* And optional data bank named "Settings" is supported. If not present, it falls back to the route data bank.


## x.y.z - 2023-xx-xx

# Changed

# Added

# Fixed

# Removed
