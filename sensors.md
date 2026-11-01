# Rear sensors (H6ISP / H4ISP)

`H6ISP::getOutputPresets` returns 84-byte rows: width at +4, height at +8, ISP camera-config index at +16, experimental flag at +74 (`0` = hidden). `CopySupportedFormatsArray` copies `sCIspCameraConfig` for that index via `H6ISPDevice::GetCameraConfig`; `VideoMaxFrameRate` is the uint16 at config +12.

Public vs experimental is therefore which config index the size row points at, not a second resolution table.

## IMX149 (iPhone 5s)

8MP. No 3840x2160.

| Output | Config index | Notes |
| --- | --- | --- |
| 1280x720 public | 1 | stock 720p30 (same mode as 1080p30) |
| 1280x720 experimental | 3 | sensor 1472x828; same config as experimental 1408x792. High-speed crop, not the 1080p60 mode |
| 1920x1080 public | 1 | stock 1080p30 |
| 1920x1080 experimental | 7 | 1080p60 unhide, sensor 2816x1584 |
| 2112x1188 | | max 16:9 |
| 3264x2448 | | max still / 4:3 |

## IMX247 (iPhone 6s / SE 1st gen)

12MP. Stock already exposes 1080p60 and 4K30. Same size table on SE 15.8.8.

| Output | Config index | Notes |
| --- | --- | --- |
| 1920x1080 experimental | 2 | high-speed |
| 3840x2160 public | 8 | stock 4K30 |
| 3840x2160 experimental | 2 | same config as high-speed 1080p, not 4K60 |
| 4096x2304 experimental | | |
| 4224x2376 | | not present |

## OV5690 (A7 iPad H6ISP)

From iPad Air 1 IPSW `iPad_64bit_12.5.8` (`16H88`, DeviceTree `iPad4,1`). The cache ships `H6ISP.mediacapture`. `getOutputPresets(22160)` (`0x5690`) returns this 19-row table. Public 1920x1080 is config index 1. There is no experimental 1920x1080. Hidden sizes: 320x240, 704x528, 1600x1200, 2048x1536, 848x640, 640x360. IMX149 is still in the same dylib (sensor 329) with experimental 1080p config 7; that path is for 5s hardware, not this table.

The same IPSW also includes iPad mini 2/3 DeviceTrees (`j85`/`j86`/`j87`) next to Air (`j71`/`j72`/`j73`).

## H4ISP (iPad 4 IPSW `14G60`)

`dsc_extractor` split of the armv7s cache. Records are 60 bytes. `CopySupportedFormatsArray` marks `Experimental` when byte +38 is 0. Config index is at +16; `VideoMaxWidth` / `VideoMaxHeight` are the sensor size at +28 / +32.

**OV5650 / OV5690** (5MP, iPad tables): public 1280x720 and 1920x1080. Hidden rows are 320x240, 704x528, 1600x1200, 2048x1536, 848x640, and on OV5690 also 640x360. No 1280x720 with max 2816x792.

**IMX145** (8MP, 4s table in the same dylib): hidden `1280x720` config 4, max **2816x792**. That is the 4s 720p60 unhide. iPad 4 DeviceTree is `iPad3,4` 5MP, so it does not take this table.
