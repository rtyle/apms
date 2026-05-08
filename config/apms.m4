dnl NAME
dnl   apms - A Pressure Monitoring Sensor
dnl
dnl SYNOPSIS
dnl   m4 [options] apms.m4 > apms.yaml
dnl
dnl DESCRIPTION
dnl   Use m4 to preprocess this YAML for esphome
dnl   because esphome's YAML parser does not support anchors and aliases
dnl   between files using !include.
dnl   m4 macro definitions and expansions are used to enhance readability
dnl   and maintainability.
dnl
dnl OPTIONS
dnl   -DNAME=name
dnl     Value of the name key of the esphome component.
dnl     This will be used for the mDNS name of the device.
ifdef(`NAME', `', `define(`NAME', `apms')')dnl
dnl
dnl   -DLOGGER_LEVEL=logger_level
dnl     Value of the level key of the logger component.
ifdef(`LOGGER_LEVEL', `', `define(`LOGGER_LEVEL', `INFO')')dnl
dnl
dnl   -DSMTP=smtp
dnl     Value is the name of the file that declares the smtp_ component
ifdef(`SMTP', `', `define(`SMTP', `smtp.m4')')dnl
---

include(m5stack_atoms3r.m4)dnl
include(m5stack_atomic_poe_base.m4)dnl
external_components:
  - <<: *m5stack_atoms3r_external_components
  - source:
      type: git
      url: https://github.com/rtyle/ping4pow
      ref: master
    components: [asio_, smtp_]

esphome:
  <<: *m5stack_atoms3r_esphome
  name: NAME

esp32: *m5stack_atoms3r_esp32

psram: *m5stack_atoms3r_psram

binary_sensor: *m5stack_atoms3r_binary_sensor

i2c: *m5stack_atoms3r_i2c

lp5562: *m5stack_atoms3r_lp5562

output: *m5stack_atoms3r_output

light:
  <<: *m5stack_atoms3r_light
  id: _light

spi: *m5stack_atoms3r_spi

display:
  - <<: *m5stack_atoms3r_display
    id: display_
    auto_clear_enabled: false
    update_interval: 1ms

ethernet: *m5stack_atomic_poe_base_ethernet

asio_:

logger:
  level: LOGGER_LEVEL

ota:
  - platform: esphome
    password: !secret NAME-ota-password

api:
  reboot_timeout: 0s
  encryption:
    key: !secret NAME-api-key

web_server:
  version: 3

debug:
  update_interval: 60s

text_sensor:
  - platform: debug
    device:
      name: debug device
    reset_reason:
      name: debug reset_reason

sensor:
  - platform: debug
    free:
      name: debug free
    block:
      name: debug block
    loop_time:
      name: debug loop_time
    psram:
      name: debug psram
    cpu_frequency:
      name: debug cpu_frequency

define(`_repeat', `ifelse(0, `$1', `', `$2`'_repeat(decr(`$1'), `$2')')')dnl
define(`_indent', `_repeat(`$1', `  ')')dnl
define(`_smtp_send_', `_indent($1)- smtp_.send:
_indent(eval(2+$1))subject: NAME $2
')dnl
define(`_smtp_send', `')dnl
define(`_smtp_define', `$1`'define(`_smtp_send', defn(`_smtp_send_'))')dnl
sinclude(SMTP)dnl
undefine(`_smtp_define')dnl
dnl
