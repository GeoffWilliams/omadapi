# omadapi

Omada on Raspberry Pi

## Whats this?
A fork of [pi-gen](https://github.com/RPi-Distro/pi-gen/) to build a custom image for Omada on raspberry pi (~4)

Features:
* [MongoDB 4.4.26](https://github.com/GeoffWilliams/mongodb-raspberrypi-binaries/releases/tag/v4.4.26)
* OpenJDK 17
* jsvc 1.3.4
* Plug and play - just burn the image ssh in on ethernet (look for IP address on router)
* Omada is already installed and set to start automatically
* Access via ssh
* Prometheus Node Exporter

## Recommended hardware

* Raspberry Pi 5 Model B 4GB edition (originally developed for Rapsberry Pi 4 Model B 1GB - works but a bit slow)
* Memory is allocated by percentage so accounts for to account for systems with more RAM. You can adjust `-XX:MaxRAMPercentage` in `/opt/tplink/EAPController/bin/control.sh`. Dont forget to leave memory for the system!

# After installation

You MUST login to Raspberry Pi via ssh and change the password on all newly flashed SD cards (`passwd` command):

* Username: `omada`
* Password: `omada`
* Hostname `omadapi` - Your router may register this if you run something good like OpenWrt otherwise check what IP address router allocated.


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

Dont - its controlled automatically by Omada

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

After upgrade, these changes are required to re-apply `omadapi` settings:

**Post upgrade steps**

1. Replace `/opt/tplink/EAPController/bin/control.sh` with contents of https://github.com/GeoffWilliams/omadapi/blob/omadapi/stageomada/10-omada/files/control.sh (and check yourself for any inc
2. Ensure vendored `mongod` is a symlink to system `mongod`:

```shell
mv /opt/tplink/EAPController/bin/mongod /opt/tplink/EAPController/bin/mongod.orig
ln -s /usr/local/bin/mongod /opt/tplink/EAPController/bin/mongod`
```

3. Reboot


## Testing

What testing have you done?

* Boot to login screen
* Login, add 2 access points
* Perform backup
* Restore backup
* Mesh wifi with 2 access points
* Firmware update access points
* 33 hour+ uptime (rebooted after loss of internet connectivity to get device firmware update notification)

## Building the image

`omdapi` is A fork of [pi-gen](https://github.com/RPi-Distro/pi-gen/) to build a custom image for omada on raspberry pi (~4) so can be updated for newer Raspbery Pi OS releases by rebasing.

To build the image yourself:

1. Read the [pi-gen docs](./docs/pi-gen.md) to setup your build environment
2. Clone the repo
3. Switch to branch `omada`
4. Adjust (or disable...) proxy configuration in `config`. It seems necessary to build with an apt proxy to prevent timeouts
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