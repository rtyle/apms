# apms (a pressure monitoring sensor)

## Motivation

The air pressure behind a thermal expansion tank's bladder should be monitored
to ensure the tank's effectiveness.
The tank will have a shrader valve on it that can be used
to pressurize the tank and, with a pressure monitoring sensor, monitor it.

There are Tire Pressure Monitoring System (TPMS) sensors 
that will work for this purpose.

* [FOBO Bike 2 TPMS](https://www.amazon.com/gp/product/B07Q21RNNB)
* [KEMIMOTO Motorcycle TMPS](https://www.amazon.com/dp/B0GK9FXB87)

However, because TMPS sensors are designed to work on rotating tires,
they are battery powered
which means the batteries need to be monitored and maintained as well.

This is a better solution.

![](README/apms.png)

## apms features

* Small, attractive package
* Display with user interface
* Display can be turned off
* Powered by [Power-over-Ethernet](https://en.wikipedia.org/wiki/Power_over_Ethernet) (PoE)
* Home Assistant integrable but not required for notification
* Email notification of pressure threshold crossings

## Architecture

### Hardware

[M5Stack](https://docs.m5stack.com/en/start/intro/intro) products are used to provide a small and attractive hardware solution
that does not require a custom enclosure.
We use an Atom core with a PoE base.
PoE power must be provided through a capable switch port or PoE injector.

* [M5Stack AtomS3R (C126)](https://docs.m5stack.com/en/core/AtomS3R)
    [Amazon](https://www.amazon.com/M5Stack-Official-0-85-inch-Atom-S3R/dp/B0F1X6JSBL)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/C126/25600008)
    [Mouser](https://www.mouser.com/ProductDetail/M5Stack/K147?qs=2FehpBK1j97%2FnUpuUy8sGA%3D%3D)
* [M5Stack Atomic PoE Base (A091)](https://docs.m5stack.com/en/atom/Atomic%20PoE%20Base)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/A091/22266234)
    [Mouser](https://www.mouser.com/ProductDetail/M5Stack/A091?qs=mELouGlnn3cabSn6LutRaQ%3D%3D)

AtomS3R has a standard [Grove](https://wiki.seeedstudio.com/Grove_System/) connector (HY2.0-4P)
for supporting an external I²C sensor
that can be threaded (by adapter) into a schrader valve.
By using a T adapter off the tank's schrader valve we can both monitor and maintain its pressure.

* [HawksHead T-Valve Adapter for TMPS Tires (TV1A)](https://www.hawksheadsystems.com/t%20valve%20adapters.html)
    [tpms.ca](https://tpms.ca/products/t-valve-adapters)
* [Godeson Air Chuck (A38)](https://www.nbgodeson.com/en/productshow-1771.html)
    [Amazon](https://www.amazon.com/dp/B07JMNGBRG)
* [TE M3200 Pressure Transducer (M32JM-000105-100PG)](https://www.te.com/en/product-20006465-00.html)
    [Digikey](https://www.digikey.com/en/products/detail/te-connectivity-measurement-specialties/M32JM-000105-100PG/9695477)
    [Mouser](https://www.mouser.com/ProductDetail/TE-Connectivity-Measurement-Specialties/M32JM-000105-100PG?qs=lc2O%252BfHJPVYobfuHIj4Lyg%3D%3D)
* [M5Stack Grove Cable (A034-B)](https://docs.m5stack.com/en/accessory/cable/grove_cable)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/A034-B/16370068)
    [Mouser](https://www.mouser.com/ProductDetail/M5Stack/A034-B?qs=81r%252BiQLm7BT61XjWHYVAMA%3D%3D)

### Software

[ESPHome](https://esphome.io/) is used because of its ability to support our chosen hardware and the potential for other choices.
It can be configured in a high level language (YAML) and will only do what you tell it to do.

## Deployment

### Hardware

The pressure transducer requires a reference vent to the atmosphere
which is accomplished via its cable.
The cable end should be terminated to a clean and dry area.
The cable wires must be adapted to a Grove connector without sealing the cable vent.

### Software

These instructions are written for a Fedora Linux platform.
Similar steps may be taken for other Linux, MacOS or Windows platforms.

Get the source from this repository by the appropriate method:

    git clone https://github.com/rtyle/apms.git
    git clone git@github.com:rtyle/apms.git

All commands documented here are executed from this directory.

    cd apms

Install python

    sudo dnf install python

Create a python virtual environment for this project.

    python -m venv .venv

Activate the virtual environment every time you want to use ESPHome within this project.

    source .venv/bin/activate

With your virtual environment activated, install ESPHome using pip:

    pip install esphome

Optionally, configure (smtp) email notification.

    cp config/smtp{.example,}.m4; vi config/smtp.m4

Configure secrets.yaml.

    cp config/secrets{.example,}.yaml; vi config/secrets.yaml

These secrets will be protected by flash encryption on/by the device.

Create an ESPHome configuration.

    (cd config; m4 apms.m4 > apms.yaml)

The first firmware flash of this ESPHome configuration
must be done with a USB cable between your computer and the M5Stack CoreS3.
**Do not interrupt this first boot!**

    esphome run config/apms.yaml

Upon the first boot after the first flash,
the secondary boot loader will encrypt the content of the flash in place.
Subsequently, only use ESPHome to flash Over The Air (OTA)
as ESPHome flashing by USB will cause the firmware to be unencrypted
which will upset the first stage bootloader to no end:

    [11:31:08.073]invalid header: 0x487325b7
    ...

To recover from this problem, the device must be flashed properly:

    bin=.esphome/build/apms/.pioenvs/apms
    python -m esptool --chip esp32s3 --port /dev/ttyACM0 write-flash --encrypt 0x0 $bin/firmware.factory.bin

Connect by ethernet to a power-over-ethernet capable port and unplug the USB cable.
Connect the switched load to the relay.
