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
dnl
dnl   -DTEMPERATURE_UNITS=units
dnl     Value is units (°F or °C) of temperature label
ifdef(`TEMPERATURE_UNITS', `', `define(`TEMPERATURE_UNITS', `°F')')dnl
ifdef(`TEMPERATURE_UNITS', `define(`TEMPERATURE_UNITS', translit(TEMPERATURE_UNITS, `a-z', `A-Z'))', `define(`TEMPERATURE_UNITS', `°F')')dnl
dnl
dnl   -DPRESSURE_UNITS=units
dnl     Value is units (psi or mbar) of pressure label and THRESHOLD
ifdef(`PRESSURE_UNITS', `define(`PRESSURE_UNITS', translit(PRESSURE_UNITS, `A-Z', `a-z'))', `define(`PRESSURE_UNITS', `psi')')dnl
dnl
dnl   -DTHRESHOLD=threshold
dnl     Pressure at or over threshold is alarming
ifdef(`THRESHOLD', `', `define(`THRESHOLD', `80')')dnl
---

include(m5stack_atoms3r.m4)dnl
include(m5stack_atomic_poe_base.m4)dnl
external_components:
  - <<: *m5stack_atoms3r_external_components
define(`_smtp_define', `define(`_smtp_defined')dnl
  - source: github://rtyle/ping4pow@master
    components: [asio_, smtp_]

asio_:

`$1'')dnl
sinclude(SMTP)dnl
undefine(`_smtp_define')dnl
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

esphome:
  <<: *m5stack_atoms3r_esphome
  name: NAME

esp32: *m5stack_atoms3r_esp32

psram: *m5stack_atoms3r_psram

i2c: *m5stack_atoms3r_i2c

lp5562: *m5stack_atoms3r_lp5562

output: *m5stack_atoms3r_output

spi: *m5stack_atoms3r_spi

ethernet: *m5stack_atomic_poe_base_ethernet

globals:
  - id: button_held_
    type: bool
    initial_value: "false"
  - id: light_brightness_target_
    type: float
    initial_value: "1.0f"
    restore_value: yes

light:
  # a completed turn_on action to brightness 0 will turn the light off but with brightness 1
  <<: *m5stack_atoms3r_light
  id: light_
  restore_mode: RESTORE_DEFAULT_ON

binary_sensor:
  <<: *m5stack_atoms3r_binary_sensor
  id: button_
  on_press:
    - globals.set:
        id: button_held_
        value: "false"
    - delay: 300ms
    - if:
        condition:
          lambda: return id(button_).state;
        then:
          - globals.set:
              id: button_held_
              value: "true"
          - light.turn_on:
              id: light_
              brightness: !lambda return id(light_brightness_target_);
              transition_length: !lambda |-
                return static_cast<uint32_t>(2000.0f * (
                  std::abs(id(light_brightness_target_) - id(light_).remote_values.get_brightness())));
  on_release:
    if:
      condition:
        lambda: return !id(button_held_);
      then:
        - if:
            condition:
              light.is_off: light_
            then:
              - light.turn_on:
                  id: light_
                  transition_length: 0ms
                  brightness: 1.0
              - globals.set:
                  id: light_brightness_target_
                  value: "0.0f"
        - lvgl.page.next:
      else:
        - if:
            condition:
              light.is_off: light_
            then:
              globals.set:
                id: light_brightness_target_
                value: "1.0f"
            else:
              - if:
                  condition:
                    lambda: return 1.0f == id(light_).current_values.get_brightness();
                  then:
                    globals.set:
                      id: light_brightness_target_
                      value: "0.0f"
                  else:
                    light.turn_on:
                      id: light_
                      transition_length: 0ms
                      brightness: !lambda return id(light_).current_values.get_brightness();
          
display:
  - <<: *m5stack_atoms3r_display
    id: display_
    auto_clear_enabled: false
    update_interval: never

text_sensor:
  - platform: debug
    device:
      name: debug device
    reset_reason:
      name: debug reset_reason

switch:
  - platform: template
    id: pressure_alarm_
    optimistic: true`'dnl
ifdef(`_smtp_defined', `
    on_turn_off:
      - smtp_.send:
          subject: !lambda return str_sprintf("apms pressure (%.2f PRESSURE_UNITS) < THRESHOLD", id(pressure_`'PRESSURE_UNITS`'_).state);
    on_turn_on:
      - smtp_.send:
          subject: !lambda return str_sprintf("apms pressure (%.2f PRESSURE_UNITS) >= THRESHOLD", id(pressure_`'PRESSURE_UNITS`'_).state);')

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

  - platform: tem3200
    id: tem3200_
    i2c_id: m5stack_atoms3r_i2c_grove
    update_interval: 60s

    temperature:
      id: temperature_celsius_
      on_value:
        - component.update: temperature_fahrenheit_`'dnl
ifelse(TEMPERATURE_UNITS, `°C', `
        - lvgl.label.update:
            id: temperature_label_
            text: !lambda return str_sprintf("%.2f TEMPERATURE_UNITS", x);')

    raw_pressure:
      id: pressure_
      internal: true
      on_value:
        - component.update: pressure_psi_
        - component.update: pressure_mbar_
        - if:
            condition:
              lambda: return id(pressure_`'PRESSURE_UNITS`'_).state < THRESHOLD;
            then:
              - logger.log:
                  level: INFO
                  format: "NAME pressure (%.2f PRESSURE_UNITS) < THRESHOLD"
                  args: [id(pressure_`'PRESSURE_UNITS`'_).state]
              - switch.turn_off: pressure_alarm_
            else:
              - logger.log:
                  level: WARN
                  format: "NAME pressure (%.2f PRESSURE_UNITS) >= THRESHOLD"
                  args: [id(pressure_`'PRESSURE_UNITS`'_).state]
              - switch.turn_on: pressure_alarm_

  - platform: template
    id: temperature_fahrenheit_
    update_interval: never
    unit_of_measurement: °F
    state_class: measurement
    device_class: temperature
    lambda: |-
      return id(temperature_celsius_).state;
    filters:
      - calibrate_linear:
          - 0 -> 32
          - 100 -> 212`'dnl
ifelse(TEMPERATURE_UNITS, `°F', `
    on_value:
      - lvgl.label.update:
          id: temperature_label_
          text: !lambda return str_sprintf("%.2f TEMPERATURE_UNITS", x);')

  - platform: template
    id: pressure_psi_
    update_interval: never
    unit_of_measurement: PSI
    state_class: measurement
    device_class: pressure
    lambda: |-
      return id(pressure_).state;
    filters:
      - calibrate_linear:
          - 1000 -> 0
          - 1700 -> 5
          - 2400 -> 10
          - 8000 -> 50
          - 13600 -> 90
          - 14300 -> 95
          - 15000 -> 100`'dnl
ifelse(PRESSURE_UNITS, `psi', `
    on_value:
      - lvgl.label.update:
          id: pressure_label_
          text: !lambda return str_sprintf("%.2f PRESSURE_UNITS", x);')

  - platform: template
    id: pressure_mbar_
    update_interval: never
    unit_of_measurement: mbar
    state_class: measurement
    device_class: pressure
    lambda: |-
      return id(pressure_psi_).state;
    filters:
      - calibrate_linear:
          - 0 -> 0
          - 1 -> 68.9476`'dnl
ifelse(PRESSURE_UNITS, `mbar', `
    on_value:
      - lvgl.label.update:
          id: pressure_label_
          text: !lambda return str_sprintf("%.2f PRESSURE_UNITS", x);')

image:
  - id: apms_
    file: apms.png
    type: rgb565
    resize: 128x128

lvgl:
  pages:
    - id: image_page_
      widgets:
        - image:
            src: apms_
            on_boot:
              - delay: 4s
              - lvgl.page.next:
    - id: widget_page_
      widgets:
        - obj:
            width: 100%
            height: 100%
            layout:
              type: flex
              flex_flow: column
              pad_row: 0
            widgets:
              - label:
                  id: pressure_label_
                  text: pressure
                  flex_grow: 1
                  width: 100%
              - label:
                  id: temperature_label_
                  text: temperature
                  flex_grow: 1
                  width: 100%
