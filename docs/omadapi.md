# Omadapi v2

Omada on Raspberry Pi

## New in Omadapi v2

* Omada 5.15.20.18
* Significant modernizations to Omada mean less workarounds needed in omadapi:
    * [JDK 9 workarounds no longer required](https://github.com/GeoffWilliams/omadapi/blob/omadapi-bookworm-12.7/stageomada/10-omada/files/omada_java_workarounds.sh)
    * MongoDB 8.0

## Whats this?
A fork of [pi-gen](https://github.com/RPi-Distro/pi-gen/) to build a custom image for Omada on Raspberry Pi 5

Features:
* [MongoDB 8.0](https://www.mongodb.com/try/download/community-edition/releases) official community version (Raspberry Pi 5 only)
* OpenJDK 17
* jsvc 1.3.4
* Plug and play - just burn the image ssh in on ethernet (look for IP address on router)
* Omada is already installed and set to start automatically
* Access via ssh
* Prometheus Node Exporter

## Raspberry Pi notes

* Raspberry Pi 5 required
* 4GB+ edition recommended
* Memory is allocated by percentage so accounts for to account for systems with more RAM. You can adjust `-XX:MaxRAMPercentage` in `/opt/tplink/EAPController/bin/control.sh`. Dont forget to leave memory for the system!

# After installation

You MUST login to Raspberry Pi via ssh and change the password on all newly flashed SD cards (`passwd` command):

* Username: `omada`
* Password: `omada`
* Hostname `omadapi` - Your router may register this if you run something good like OpenWrt or opnsense, otherwise check what IP address router allocated.


## Omada
When booted, Omada will be available at:
* http: [http://omadapi:8088](http://omadapi:8088) (redirects to TLS port)
* https: [https://omadapi:8043](https://omadapi:8043)

Where `omadapi` is the hostname or IP address of the pi. TLS certificate is self-signed so you have to click-through the browser security warning.

You will be prompted to setup a user.

## Start/stop Omada

```shell
/etc/init.d/tpeap start
/etc/init.d/tpeap stop
```

## Logs?

In `/opt/tplink/EAPController/logs/`

## Start/stop mongodb

Don't - its controlled automatically by Omada

## Backup/Restore

All done through the Omada UI, [instructions from tp-link](https://www.tp-link.com/us/support/faq/2677/). These are for the hardware controller but should still apply to Omada software release since its the same UI.

## Upgrades

### Option 1 (swap)

Backup settings:

settings -> maintenance -> backup -> click export, a file will be prepared and then it downloads.

1. Export settings from Omada UI
2. Shut down the pi
3. Flash a new image on an additional SD card
4. Boot image
5. **ssh in and set password**
6. Go to Omada UI and import settings

If there are problems just swap back to the old SD card.


### Option 2 (in-place)

This process is riskier since your operating on a running device... if upgrade breaks for some reason now you have degraded network _and_ a broken controller. Make sure you have a backup before starting.

Omadapi is just a regular Linux system so vendor upgrade path should work so follow tp-link instructions to update the Omada debian package.

## Testing

What testing have you done?

* Boot to login screen
* Login, add 2 access points
* Perform backup
* Restore backup
* Mesh wifi with 2 access points
* Firmware update access points
* 7+ day uptime

## Building the image

To build the image yourself:

1. Read the [pi-gen docs](../README.md) to setup your build environment
2. Clone the repo
3. Switch to branch `omadapi_v2`
4. Setup your `sources.list` lines in `config` (eg to point to a nexus). Local caching seems required to avoid timeout
4. Run `build-docker.sh`
5. Burn the `full` image that the script generates with [Balena Etcher](https://etcher.balena.io/) or similar, then put SD card in pi and power on
6. For publising, rename the image file to include the version, eg:`omadapi-5.13.22-0.zip`

## Status

* Larger deployments untested, please report successes/failures
* From tp-link? Please feel free to make some raspbery pi image for the community based on this!
* Interested to help? Please open a ticket...

## Acknowledgements
* Lots of good infos on the [Omada Raspbery Pi forum thread](https://community.tp-link.com/en/business/forum/topic/528450)
* `themattman` for providing a [guide to setting up old versions of MongoDB on Raspberry Pi](https://github.com/themattman/mongodb-raspberrypi-binaries)
* [pi-gen](https://github.com/RPi-Distro/pi-gen/) - entire build system