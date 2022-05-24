# ClashM
Clash (Meta) in Magisk with Services.
  
Not supporting IPv6 (yet).


## Installation
Download installer zip file from releases.

Install it via Magisk Manager.

## Uninstallation
Uninstall modules via Magisk Manager.

Data directory automatically removed.

## Configuration
Data directory stored on `/data/adb/ClashM`

ClashM using `config.yaml` by default

Modules config at `/data/adb/modules/ClashM/scripts/clashm.config`

`MERGE=true` will force merge between `base.yaml` and `proxies.yaml` into `config.yaml`

Run/Logs directory in `/data/adb/modules/ClashM/run`

## Changelogs
### v0.2.3
  - add force option to skip port & tun device verifier.
### v0.2.2
  - Clean up.
  - Fix get TUN interface on forward device.
  
### v0.2.1
  - Using service.d.
  - Fix port handler.
  - Using TUN mode by default.

### v0.2.0
  - Add notification.
  - DNS & TPROXY port handler.
  - Better tun device verification.
  - Update base, example configs.
  - Update yacd.

### v0.1.1
  - Fix core.log output.
  
### v0.1.0
  - Moved data dir to /data/adb.
  - Separate clashm.config in scripts dir.
  - Updated database.
  - Update meta core.
  
### v0.0.1
  - Clean up code.
  - Update core.

### v0.0.0
  - Initial release.

