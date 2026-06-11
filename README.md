# apms (a pressure monitoring sensor)

## Motivation

The air pressure behind a thermal
[expansion tank](https://en.wikipedia.org/wiki/Expansion_tank)'s
bladder should be monitored to ensure the tank's effectiveness.
The tank will have a [Schrader valve](https://en.wikipedia.org/wiki/Schrader_valve) on it that can be used
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

* Measures pressure (psi/mbar) and temperature (°F/°C)
* Derives molar density per the [ideal gas law](https://en.wikipedia.org/wiki/Ideal_gas_law)
* Small, attractive package
* Display with user interface
* Display can be turned off
* Powered by [Power-over-Ethernet](https://en.wikipedia.org/wiki/Power_over_Ethernet) (PoE)
* Smart-home integrable
* Pressure measurement and threshold alarms
* E-mail notification

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
for supporting an external I²C pressure transducer
that can be threaded (by way of an air chuck) into a Schrader valve.
External I²C pullup resistors are required.
See TE M3200 datasheet: “In most cases, 4.7kΩ is a reasonable choice.“
These can be soldered inline or applied to a grove to grove connector.
For bench testing, a grove to 4-pin extension connector and a breadboard are convenient.

* [M5Stack Grove Cable (A034-B)](https://docs.m5stack.com/en/accessory/cable/grove_cable)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/A034-B/16370068)
    [Mouser](https://www.mouser.com/ProductDetail/M5Stack/A034-B?qs=81r%252BiQLm7BT61XjWHYVAMA%3D%3D)
* [M5Stack Grove to Grove extension connector (A040)](https://docs.m5stack.com/en/accessory/converter/grove2grove)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/A040/16370069)
    [Mouser](https://www.mouser.com/ProductDetail/170-A040)
* [M5Stack Grove to 4P extension connector (A099)](https://docs.m5stack.com/en/accessory/converter/grove_to_4p)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/A099/14318608)
    [Mouser](https://www.mouser.com/ProductDetail/170-A099)
* YAGEO 4.7kΩ resistors (MFR25SFRF52-4K7)
    [Digikey](https://www.digikey.com/en/products/detail/yageo/MFR25SFRF52-4K7/9143469)
    [Mouser](https://www.mouser.com/ProductDetail/603-MFR25SFRF52-4K7)
* [TE M3200 Pressure Transducer (M32JM-000105-100PG)](https://www.te.com/en/product-20006465-00.html)
    [Digikey](https://www.digikey.com/en/products/detail/te-connectivity-measurement-specialties/M32JM-000105-100PG/9695477)
    [Mouser](https://www.mouser.com/ProductDetail/TE-Connectivity-Measurement-Specialties/M32JM-000105-100PG?qs=lc2O%252BfHJPVYobfuHIj4Lyg%3D%3D)
* [Godeson Air Chuck (A38)](https://www.nbgodeson.com/en/productshow-1771.html)
    [Amazon](https://www.amazon.com/dp/B07JMNGBRG)
  
Optionally, by using a T-valve adapter off the tank's Schrader valve, pressure can be monitored and maintained.

* [HawksHead T-Valve Adapter for TMPS Tires (TV1A)](https://www.hawksheadsystems.com/t%20valve%20adapters.html)
    [tpms.ca](https://tpms.ca/products/t-valve-adapters)

For bench testing, a capped tank valve can substitute for the expansion tank.

* Godeson ¼″ NPT tank valve
    [Amazon](https://www.amazon.com/dp/B0CPPBSFV5)
* [uxcell ¼″ NPT cap (f24032100ux0225)](https://www.harfington.com/products/p-1684955?variant=46634064511225)
    [Amazon](https://www.amazon.com/dp/B0DLKNM5CG)

For the most accurate measure of molar density, a dynamic measure of barometric pressure must be provided;
otherwise, a configurable static barometric pressure is used.
For this purpose, an M5Stack Unit ENV-III sensor can be inserted onto the I²C bus with an M5Stack Grove T header.
This sensor will obivate the need for separate 4.7kΩ pullup resistors as they are included in the sensor package.

* [M5Stack Unit ENV-III (U001-C)](https://docs.m5stack.com/en/unit/envIII)
    [Amazon](https://www.amazon.com/dp/B0FNNGJ7QJ)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/U001-C/14672141)
    [Mouser](https://www.mouser.com/ProductDetail/M5Stack/U001-C?qs=e8oIoAS2J1R2mB7ZY1%252BSZg%3D%3D)
* [M5Stack Grove T header (U039-B)](https://docs.m5stack.com/en/accessory/converter/grove_t)
    [Amazon](https://www.amazon.com/dp/B0GZDL4NZ6)
    [Digikey](https://www.digikey.com/en/products/detail/m5stack-technology-co-ltd/U039-B/16370074)
    [Mouser](https://www.mouser.com/ProductDetail/M5Stack/U039-B?qs=81r%252BiQLm7BS%2F8qLurmjgEQ%3D%3D)

### Software

[ESPHome](https://esphome.io/) is used because of its ability to support our chosen hardware and the potential for other choices.
It can be configured in a high level language (YAML) and will only do what you tell it to do.
The sensor can be integrated into any smart home that is compatible with ESPHome devices.

* [Home Assistant and ESPHome](https://esphome.io/guides/getting_started_hassio/)
* [Homey with ESPHome Controller](https://homey.app/en-us/app/com.ugrbnk.esphome/ESPHome-Controller/)

## Deployment

### Hardware

The pressure transducer requires a reference vent to the atmosphere
which is accomplished via its cable.
The cable end should be terminated to a clean and dry area.
The cable wires must be adapted to a Grove connector without sealing the cable vent.
The adaptation must include I²C pullup resistors – perhaps by way of an M5Stack Unit ENV-III sharing the bus.

Each ¼″ NPT fitting should use a high quality thread sealant.

* [Blue Monster PFTE thread seal tape (70885)](https://cleanfit.com/blue_monster_ptfe_thread_seal_tape_70885.shtml)
    [Home Depot](https://www.homedepot.com/pep/306136345)
* [Blue Monster thread sealant with PFTE (76009)](https://cleanfit.com/blue_monster_industrial_grade_thread_sealant_76001.shtml)
    [Home Depot](https://www.homedepot.com/pep/306136383)

The gaskets on the Schrader valve connections should be sealed as well.

* [Refrigeration Technologies Nylog Blue gasket & thread sealant (RT201BP)](https://www.refrigtech.com/nylog-blue/)
    [Amazon](https://www.amazon.com/dp/B008HOSQQQ)
    [Home Depot](https://www.homedepot.com/p/333685992)

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

Configure (smtp) email notification.

    cp config/smtp{.example,}.yaml; vi config/smtp.yaml

Configure secrets.yaml.

    cp config/secrets{.example,}.yaml; vi config/secrets.yaml

These secrets will be protected by flash encryption on/by the device.

Test the ESPHome configuration.

    esphome config config/main.yaml

Substitutions can be made on the esphome command line to override the defaults.
For example,

    esphome \
        -s name apms-tank\
        -s smtp false\
        -s pressure_unit mbar\
        -s temperature_unit celsius\
        -s logger_level DEBUG\
        config main.yaml

By default, `${name}` in the yaml configuration, is substituted with `apms`.
This will be used to name the `esphome` component and must follow the [ESPHome core configuration](https://esphome.io/components/esphome/) guidelines.

Choice of a different name will require a different `${name}_.yaml` file.

    cp config/{apms,${name}}_.yaml; vi config/${name}_.yaml

By default, this file is empty but one can use it to override some configuration settings.
For example, this could be used to override any of the default `!secret` selections.

    api:
      encryption:
        key: !secret apms-tank-api-encryption-key
    
    ota:
      - id: !extend ota_
        password: !secret apms-tank-ota-password
    
    smtp_:
      - id: !extend smtp__
        password: !secret apms-tank-smtp-password

The first firmware flash of this ESPHome configuration
must be done with a USB cable between your computer and the M5Stack AtomS3R.
**Do not interrupt this first boot!**

    esphome run config/main.yaml

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

## Usage

By pressing the integrated display button, **apms** will rotate through its splash screen, pressure meter, thermometer and molar density meter.
Holding the button will dim the display to the desired brightness, including off.
The display can be restored to full brightness with another button hold (or press).

[Homey](https://homey.app/) integration can be done using [ESPHome Controller](https://homey.app/en-us/app/com.ugrbnk.esphome/ESPHome-Controller)'s
ESPHome Device. Name the device, identify it by a static IP address or dynamic mDNS name (e.g. apms.local) and enter the api-key from secrets.yaml. Use [Homey Insights](https://homey.app/en-us/features/insights/) to track the pressure and temperature which should be related per the [ideal gas law](https://en.wikipedia.org/wiki/Ideal_gas_law). Use the device in an [advanced flow](https://homey.app/en-us/features/advanced-flow/) to react to events.

[Home Assistant](https://www.home-assistant.io/) integration should be similar.

