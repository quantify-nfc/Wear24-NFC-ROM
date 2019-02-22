# Wear24 NFC ROM

**THIS REPO IS STILL UNDER CONSTRUCTION**

[![Build Status](https://travis-ci.org/davwheat/Wear24-NFC-ROM.svg?branch=master)](https://travis-ci.org/davwheat/Wear24-NFC-Kernel)

This project is a modified Android ROM for the Quanta's `dorado` (sold as the Verizon Wear24) to pair with our kernel. Our aim is to get the watch to support NFC, a feature Verizon promised, yet never shipped. In the future, greater modifications may be made to support more features or update to newer systems.

## Discord

https://discord.gg/8XyTeUC

## Branches

You are on **NFC**.

This repository has three main branches: `master`, `nfc` and `release`. These branches are semi-equivalent to Google Chrome's Stable, Beta and Dev update channels.

`master` is *normally* stable. We generally don't push changes here unless we are confident that they work. We don't recommend flashing your device using this code despite us calling it 'stable'.

`nfc` is unstable and experimental. Likely broken half the time. **DO NOT FLASH FROM HERE UNLESS YOU WANT TO** (probably) **BRICK YOUR DEVICE!**

`release` is our end user branch. This is where we will distribute the ROM when there is an actual reason to flash it. Our releases are automagically built by our [Travis CI integration](https://travis-ci.org/davwheat/Wear24-NFC-ROM/branches) and uploaded to [GitHub releases](https://github.com/davwheat/Wear24-NFC-ROM/releases).

## Building

`android-tools-fsutils` is needed for `make_ext4fs`!

`sudo apt install android-tools-fsutils`

### Automatic

Extract the existing `system.img`, add our own files, and rebuild using `./build.sh`.

### Manual

**NOT RECOMMENDED**

*Coming soon*

