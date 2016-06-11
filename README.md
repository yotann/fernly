Fernly - Fernvale Reversing OS
========================================

This is a project to reverse-engineer the MTK2502, MTK6260, MTK6261, and
related SoCs from Mediatek. These chips are often found in cheap Chinese-brand
dumbphones and smartwatches, and are also used in the
[Fernvale](http://shop.sysmocom.de/products/fernvale-mt6260-reverse-engineering-development-kit-dvt2)
and [LinkIt](https://www.seeedstudio.com/item_list.html?category=18)
development boards. This project is not affiliated with Mediatek in any way.

This project primarily consists of the Fernly OS, a trivial operating system
designed for experimentation and reverse engineering of these Mediatek chips.
It also includes some documentation:

 -  [Fernly FlashROM backup](docs/fernly-flashrom.md)
 -  [Memory map](docs/memory-map.md)


Important links
---------------

 -  [Original blog post](http://www.bunniestudios.com/blog/?p=4297)
 -  [Forums](http://www.kosagi.com/forums/index.php)
 -  [Port of NuttX OS to MTK6260](https://github.com/sutajiokousagi/fernvale-nuttx)
 -  [Port of Fernly OS to MTK2502](https://github.com/mandl/fernly)
 -  [Port of Fernly OS to MTK6261](https://github.com/isogashii/fernly/tree/fernly6261/)


Setting up cross compilation
----------------------------
### Linux

    git clone https://github.com/robertfoss/setup_codesourcery.git
    sudo setup_codesourcery/setup.sh
    /usr/local/bin/codesourcery-arm-2014.05.sh


Building Fernly
---------------

To compile, simply run "make".  If you're cross-compiling, set CROSS_COMPILE to
the prefix of your cross compiler.  This is very similar to how to compile for Linux.

For example:

    make CROSS_COMPILE=arm-none-linux-gnueabi-


Running Fernly
--------------

To run, connect the target device and run the following command:

    ./build/fernly-usb-loader -s /dev/fernvale ./build/usb-loader.bin ./build/firmware.bin

This will open up /dev/fernvale, load usb-loader.bin as a stage 1 bootloader,
and then load (and jump to) firmware.bin as stage 2.  Optionally, you can add
a stage 3 file by specifying it as an additional argument.

Many 3rd-party devices enter bootloader mode only for a short window (~1s)
after being connected to USB. A device almost certainly should be "off". Some
devices require that battery is removed, while some - don't. To accommodate
such cases, there's -w (wait) option. Run fernly-usb-loader, and only
then connect a device to USB. This will allow to try various combinations
mentioned above with greater comfort (you need to disconnect and poweroff
device after each try, and restart fernly-usb-loader).

    ./build/fernly-usb-loader -w -s /dev/ttyUSB0 ./build/usb-loader.bin ./build/firmware.bin

Linux Notes
-----------

Since Fernvale is based on a Mediatek chip, ModemManager will, by default,
try to treat it as a modem and make it available for network connections.
This is undesirable.

To work around this problem, create a udev rule under /etc/udev/rules.d/
called 98-fernvale.rules with the following contents:

    SUBSYSTEM=="tty", ATTRS{idVendor}=="0e8d",\
        ATTRS{idProduct}=="0003",\
        MODE="0660", SYMLINK+="fernvale"

    ACTION=="add|change", SUBSYSTEM=="usb",\
        ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="0e8d",\
        ATTRS{idProduct}=="0003",\
        ENV{ID_MM_DEVICE_IGNORE}="1"

OSX Notes
---------
The default OSX CDC matching seems to miss the Fernvale board. Use [fernvale-osx-codeless](https://github.com/jacobrosenthal/fernvale-osx-codeless) to get a com port.


Licensing
---------

Fernly is licensed under the BSD 2-clause license (see LICENSE).

Previous versions of fernly linked against division libraries taken from U-Boot,
which were licensed under GPL-2.  These files have been removed.

Instead, we supply a version of libgcc.a.  This file was extracted from a
standard gcc toolchain, specifically:

    https://code.google.com/p/yus-repo/downloads/detail?name=arm-none-eabi-4.6-armv5.tar.gz

It has not been modified, and its distribution here should be covered under
the "runtime exception".
