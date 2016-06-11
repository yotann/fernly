SPI and Flashrom
================

Backing up firmware
-------------------

Fernly doesn't require changing a firmware stored in FlashROM of
your device - it runs completely from RAM. You may still want
to backup the original firmware for various reasons. Following
gives a walkthru how to do this.

1. Check out the latest flashrom HEAD:

        svn co http://code.coreboot.org/svn/flashrom/trunk flashrom

   Using latest HEAD is recommended, as it may have more chip definitions,
   and there's less chance it won't recognize your FlashROM.

2. Apply flashrom-fernvale.patch from fernly:

        patch -p0 <flashrom-fernvale.patch

3. You may need to install libusb-0.1 development headers to build it
   (0.1 is "old" libusb, many projects use modern 1.0 version). For ubuntu:

        apt-get install libusb-dev

4. Build with:

        make WARNERROR=no

5. Start fernly without "-s" (shell) switch:

        ./build/fernly-usb-loader -w /dev/ttyUSB0 ./build/usb-loader.bin ./build/firmware.bin

6. Run flashrom to dump device FlashROM to a file:

        ./flashrom --programmer fernvale_spi:dev=/dev/ttyUSB0 --read flash.dat

   If you're unlucky, it may report that it cannot recognize your device has
   a ROM it can't recognize. If so, follow flashrom documentation on what to do.

   Otherwise, expect that reading 16MB of flash to take up to 10 minutes -
   without any progress indicator or something.

7. Refer to flashrom documentation for writing (generally it's as simple
   as giving --write option instead of --read).

Fernly flashrom protocol
------------------------

Fernly includes a special 'flashrom' mode that allows for direct communication
with the flashrom program to manipulate the onboard SPI.  The protocol is
binary, and can be entered by issuing the following command:

    spi flashrom

Fernly will respond with a binary 0x05, indicating it is ready.

The format of the protocol is very simple.  The host writes the number of bytes
to write, then the number of bytes to read, and then writes the data to send
to the flash chip.  It then reads the requested number of bytes.  For
example, to send a 2-byte command '0xfe 0xfa' followed by a 3-byte response,
write the following data to the serial port:

    | 02 03 fe fa |

Then read three bytes of data from the serial port.

A maximum of 255 bytes may be transmitted and received at one time, though
in practice these numbers may be smaller.

To exit 'spi flashrom' mode and return to fernly, read/write zero bytes.
That is, send the following packet:

    | 00 00 |
