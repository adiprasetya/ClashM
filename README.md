# ClashM
Clash (Meta) in Magisk with Services.

Using TUN by default.

Unsupport TPROXY method.

IPv6 should work fine.


## Installation
Download installer zip file from [releases](https://github.com/adiprasetya/ClashM/releases).

Install it via Magisk Manager.

## Uninstallation
Uninstall modules via Magisk Manager.

Data directory automatically removed.

## Configuration
Data directory stored on `/data/adb/ClashM`

Using `config.yaml` by default

ClashM configuration at `/data/adb/modules/ClashM/scripts/configuration`

`MERGE=true` will force merge `base.yaml` and `proxies.yaml` into `config.yaml`

Run/Logs directory stored on `/data/adb/modules/ClashM/run`

## Changelogs
### v1.0.1
  - change dashboard to [YACD MetaCubeX](https://github.com/MetaCubeX/yacd)
  - update meta core

### v1.0.0
  - removed TPROXY iptables support.
  - removed useless/bloated features.
  - rename `clashm.config` to `configuration`
  - cleaning up code.
  - removed `geo-database` on zip installer.

### v0.2.3
  - Add force option to skip port & tun device verifier.

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

