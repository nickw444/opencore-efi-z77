# GA-Z77X-D3H Hackintosh Notes

## Hardware Details
| Component | Details  |
|---|---|
|Mobo| GA-Z77X-D3H|
|GFX| GV-RX580GAMING-8GD|
| | Intel HD4000 |
| Audio | Via VT2021 |
| Network | Atheros AR8151 v2.0 |
|  | BCM943602CS (Identified as BCM94360CD) AirPort Extreme  (0x14E4, 0x133) |
| Bluetooth | BCM943602CS |
| USB | Intel USB2/3 7 series chipset |
|  | Jmicron Controller (lower 4 ports on rear), **Unsupported** |

## To do

* Fix kernel panic on sleep wake

## Guides

* https://desktop.dortania.ml/
* https://usb-map.gitbook.io/project/
* https://github.com/corpnewt/USBMap

## Past Success for similar board

* https://www.reddit.com/r/hackintosh/comments/7cuccm/gaz77xd3h_high_sierra_success/
* https://www.tonymacx86.com/threads/near-perfect-high-sierra-setup-on-z77x-ud5h-ivy-bridge-i5-rx-560.252663/

## Sleep/Wake

* Disable hibernate
    * sudo pmset -a autopoweroff 0
    * sudo pmset -a hibernatemode 0
* Wake causes: https://www.cnet.com/news/how-to-find-system-wake-causes-in-os-x/
* syslog | grep Wake
* log show --style syslog | fgrep "Wake reason"
* Turns out random wakes during the night was due to power nap. Disabled power nap in system preferences and appears to have solved the issue
* Serial Port must be disabled in the BIOS [Source](https://www.insanelymac.com/forum/topic/339369-wake-issues-since-catalina/?tab=comments#comment-2691528), without this a KP when resuming from sleep will occur.

```
jq -r 'map(.timestamp | match("\\d+\\-\\d+\\-\\d+\\s+\\d+:\\d+") | .string ) | .[]' | uniq

log show --start "2019-05-02 12:00:00" --end "2019-05-02 18:00:00"  --style json | jq -r 'map(.timestamp | match("\\d+\\-\\d+\\-\\d+\\s+\\d+:\\d+") | .string ) | .[]' | uniq
```

## Post Setup Checks

Things to check post-setup/upgrade

* Check TRIM is enabled on all drives
* Ensure CPU power management is working correctly
* Check USB Mapping is correct in IOReg/IORegistryExplorer

## Bootloader

OpenCore used as boot loader (Clover replacement). Bootloader config is revisioned via git: https://gitlab.com/nickw444/opencore-efi (this repo)

## Hardware

### BIOS Settings

Saved configurations can be found in [resources/bios-config/](resources/bios-config/)

#### Diffable Settings:

* Defaults as base

##### BIOS Features
* Fast Boot: Disabled
* limit CPUID Max: Disabled
* Execute Disable Bit: Enabled
* Intel Virtualization Technology Enabled
* OS Type: Windows 8 WHQL
* CSM Support: Always
    * UEFI Only
    * LAN PXE Boot Option ROM: Disabled
    * Storage Boot Option Control: Disabled
* Other PCI Device ROM priority: UEFI OpROM
* Network Stack: Disabled
* Secure Boot: Enabled
* Secure Boot Mode: Standard

##### Peripherals

* Sata Controllers: Enabled
* Sata Mode Selection: AHCI
* XHCI Pre Boot Driver: Enabled
* xHCI Mode: AUTO
    * HS Port 1 Switchable: Enabled
    * HS Port 2 Switchable: Enabled
    * HS Port 3 Switchable: Enabled
    * HS Port 4 Switchable: Enabled
    * xHCI Streams: Enabled
* USB2.0 Controller: Enabled
* Audio Controller: Enabled
* Init Display First: Auto
* Internal Graphics: Enabled
* Internal Graphics Memory Size: 32M
* DVMP Total Memory Size: 128M
* Intel Rapid Start Technology: Disabled
* Legacy USB Support: Enabled
* XHCI Hand-off: Enabled
* EHCI Hand-off Disabled
* Port 60/64 Emulation: Disabled
* USB Storage Devices:
    * 1.00: A/uto
    * Onboard USB3 Controller #1: Enabled
    * OnBoard LAN Controller #1: Enabled
    * PCIE Slot Configuration: AUTO
* SUperIO Configuration
    * Serial POrt A: Disabled
* Intel SMart Connect Technology:
    * ISCT Configuration: Disabled
* Marvel ATA Controller Configuration
    * GSATA Controller: AHCI Mode

##### Power Management

* Resume by Alarm: Disabled
* ERP: Disabled
* High Precision Event Timer: Enabled
* Soft off by PWR BUTTON: Instanced Off
* Internal Graphics Standby Mode: Enabled
* Internal Graphics Deep Standby Mode: Enabled
* AC Back: Always Off
* Power On By Keyboard: Disabled
* Power On By Mouse: Disabled


### Audio 📣

Works OOB with [AppleALC](https://github.com/acidanthera/AppleALC/) using `inject=5`

### USB

USBInjectAll to customize port mapping. USB3 "working" out of the box.

USB3 front panel connector does not able to be able to keep USB3 HDD connected for any meaningful amount of time. Possibly an issue with power?

Used [USBMap](https://github.com/corpnewt/USBMap) to generate an injector kext to remove UIA, however this motherboard has some funky internal hub setup, and I couldn't change the injected hub ports with this kext. Instead had to use a [customized DSDT](resources/DSDT/SSDT-UAIC.dsl)

USB Map plist for USBMap tool can be found in [resources/USBMap/USB.plist](resources/USBMap/USB.plist).


#### Port Mapping

**Front Panel**

From left to right:

* P1: (Spliced internally, used for BT Controller - see below)
    * USB2: HS01 (routed via XHC controller)
    * USB3: SS01
* P2:
    * USB2: HS02 (routed via XHC controller)
    * USB3: SS02
* P3:
    * USB2: PR11 (Internal hub), HP15
* P3:
    * USB2: PR11 (Internal hub), HP16

**Back Panel**

From top to bottom, left to right

* P1:
    * USB2: PR21 (Internal hub), HP26
* P2:
    * USB2: PR21 (Internal hub), HP25
* P3:
    * USB2: PR21 (Internal hub), HP24
    * USB3: SS03
* P4:
    * USB2: PR21 (Internal hub), HP23
    * USB3: SS04

![USB Map](resources/img/usb-map.png)

### Ethernet 🕸

Card is Atheros AR8151 v2.0. Compiled my own version of AtherosL1cEthernet.kext against High Sierra frameworks. Works in Mojave.

* https://github.com/al3xtjames/AtherosL1cEthernet
* https://www.tonymacx86.com/threads/i-need-kext-for-ethernet-with-mojave-with-ga-z77-ds3h.270126/
* https://www.tonymacx86.com/threads/atherosl1cethernet-tweaked-for-high-sierra.236867/

### Intel GPU HD4000 🖥

WIP: Currently causing KP when resuming from sleep.

Current `ig-platform-id`: `0x01620007`. iGPU is being used as secondary with dGPU as primary.


**Known IDs**

| AAPL,ig-platform-id | Memory (MB) | Pipes | Ports  | Comment | Notes From Testing |
| --- | --- | --- | --- | --- | --- |
| `0x01660000` | 96 | 3 | 4 |  | |
| `0x01660001` | 96 | 3 | 4 |  | |
| `0x01660002` | 64 | 3 | 1 | No DVI | |
| `0x01660003` | 64 | 2 | 2 |  | |
| `0x01660004` | 32 | 3 | 1 | No DVI | |
| `0x01620005` | 32 | 2 | 3 |  | |
| `0x01620006` | 0  | 0 | 0 | No display | Cause panic on wake from sleep |
| **`0x01620007`** | 0  | 0 | 0 | No display | |
| `0x01660008` | 64 | 3 | 3 |  | |
| `0x01660009` | 64 | 3 | 3 |  | |
| `0x0166000a` | 32 | 2 | 3 |  | |
| `0x0166000b` | 32 | 2 | 3 |  | |


**Official Docs**

* https://github.com/acidanthera/WhateverGreen/blob/master/Manual/FAQ.IntelHD.en.md


**Other Docs**

* https://gist.github.com/al3xtjames/c46e368c3227cdc58e900f7117f34571
* http://blog.stuffedcow.net/2012/07/intel-hd4000-qeci-acceleration/
* https://www.reddit.com/r/hackintosh/comments/7m8uah/enabling_igpu_gpu/
* https://www.tonymacx86.com/threads/dual-graphics-headless-igpu-amd-hardware-acceleration-on-mojave.267554/

### CPU Power Management

* ssdtprGen.sh https://github.com/Piker-Alpha/ssdtPRGen.sh
* Confirm with https://github.com/Piker-Alpha/AppleIntelInfo
* https://www.insanelymac.com/forum/topic/304369-how-to-check-your-states-%E2%80%93-using-aicpminfo-msrdumper-or-appleintelinfo/


### Bluetooth / WiFi w/ Broadcom Card

BCM943602CS: 802.11ac 3x3, (1.3Gbps / 5GHz) + Bluetooth 4.1. The module will be applied in MacBook Pro computers (2015)

* BCM43602 14e4:43ba supported in 3.17+ (brcmfmac)
* BCM43602 14e4:43bb 2.4GHz device, supported in 3.19+
* BCM43602 14e4:43bc 5GHz device, supported in 3.19+


Bluetooth USB connection must be connected to XHC bus and marked as internal (DSDT type 255), otherwise this will cause random wake as soon as machine goes to sleep. Recall all USB ports on the back panel are routed via EH02 via a hub, so we cannot use that, and instead must splice the internal USB ([source](https://github.com/al3xtjames/Gigabyte-GA-Z77X-macOS-Install/issues/65#issuecomment-312686694))

> What worked for me in the same fenvi is making sure that the connector type for the internal usb header is set to internal port. I used fbpatcher to do it. [1](https://www.reddit.com/r/hackintosh/comments/ayou5v/fenvi_fvt919_bluetooth_not_working/ei2nymc/)

Previously used a USB3 20 pin splitter to splice, but this caused issue with USB detection from the FP ports. Instead a splice was made directly in the cable from the case. May need to "unsplice" if a replacement mobo has better internal USB support.

**Bluetooth Firmware Issues**

This didn't seem necessary for getting BT support for Catalina, however I recall that once the firmware is loaded once the issue goes away. The issue may re-appear when returning back from Windows (which clobbers the firmware)

Add device ID so the firmware is loaded at boot ([Source](https://github.com/the-darkvoid/BrcmPatchRAM/issues/35)):

```xml
        <key>0a5c_21ff</key>
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.no-one.BrcmPatchRAM2</string>
            <key>DisplayName</key>
            <string>Broadcom BCM20702 Bluetooth 4.0 +HS USB Device</string>
            <key>FirmwareKey</key>
            <string>BCM20702A1_001.002.014.1443.1463_v5559</string>
            <key>IOClass</key>
            <string>BrcmPatchRAM2</string>
            <key>IOMatchCategory</key>
            <string>BrcmPatchRAM2</string>
            <key>IOProviderClass</key>
            <string>IOUSBHostDevice</string>
            <key>idProduct</key>
            <integer>8703</integer>
            <key>idVendor</key>
            <integer>2652</integer>
        </dict>
```

> The thing I'd check is the Vendor and drvice IDs to ensure they're exactly right. For the BCM94360CD (the three-antenna for WiFi, one antenna for BT4.0 design), the Bluetooth controller needs to be 05ac:828d and the WiFi needs to be 106b:0111 (those are technically sub vendor and device IDs, I guess because the main vendor and device IDs of 14e4:43a0 refer to the underlying Broadcom chip itself). Apparently there are other Broadcom 4360 chipset-based cards with different sub product IDs like 0136 that get sold and aren't the exact right models and thus don't wind up unlocking every feature properly.

[Source](https://www.reddit.com/r/hackintosh/comments/a8mwiz/the_trials_and_tribulations_of_native_wifibt_on_a/ecdzccb/)

> Fenvi T-919 is the easy answer, it’s a Broadcom BCM94360-based card that should support native functionality in macOS. You will need a driver for it for Windows. You could also get an adapter and an Apple official BCM94360 card (a 2-antenna -CS or -CS2 from a MacBook Air, or a 4-antenna -CD from an iMac) and just use the Bootcamp drivers in Windows (not sure about Linux, sorry).

[Source](https://www.reddit.com/r/hackintosh/comments/aaili7/imessage_airdrop_handoff_etc/)


**Handoff Stopped Working**

> Log in and out of icloud on all your devices. After that, wait a couple hours / days and literally do nothing, it'll start working out of thin air. Happened to countless users including me with a native Fenvi t919.

[Source](https://www.reddit.com/r/hackintosh/comments/9ynok0/handoffcontinuity_not_working_after_wifibluetooth/ea3lrkp/)

