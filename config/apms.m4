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
dnl   -DNAME=value
dnl     Value of the name key of the esphome component.
dnl     This will be used for the mDNS name of the device.
ifdef(`NAME', `', `define(`NAME', `apms')')dnl
dnl
dnl   -DLOGGER_LEVEL=value
dnl     Value of the level key of the logger component.
ifdef(`LOGGER_LEVEL', `', `define(`LOGGER_LEVEL', `INFO')')dnl
dnl
dnl   -DSMTP=value
dnl     Value is the name of the file that declares the smtp_ component
ifdef(`SMTP', `', `define(`SMTP', `smtp.m4')')dnl
dnl
dnl   -DPRESSURE_UNIT=value
dnl     Unit value (psi or mbar) for pressure
ifdef(`PRESSURE_UNIT', `define(`PRESSURE_UNIT', translit(PRESSURE_UNIT, `A-Z', `a-z'))', `define(`PRESSURE_UNIT', `psi')')dnl
dnl
dnl   -DPRESSURE_FORMAT=value
dnl     Format for pressure presentation
ifdef(`PRESSURE_FORMAT', `', `define(`PRESSURE_FORMAT', ifelse(PRESSURE_UNIT, `psi', %.1f, %.0f))')dnl
dnl
dnl   -DPRESSURE_MINIMUM=value
dnl     Minimum pressure value supported by meter
ifdef(`PRESSURE_MINIMUM', `', `define(`PRESSURE_MINIMUM', ifelse(PRESSURE_UNIT, `psi', 0, 0))')dnl
dnl
dnl   -DPRESSURE_MAXIMUM=value
dnl     Maximum pressure value supported by meter
ifdef(`PRESSURE_MAXIMUM', `', `define(`PRESSURE_MAXIMUM', ifelse(PRESSURE_UNIT, `psi', 100, 7000))')dnl
dnl
dnl   -DPRESSURE_THRESHOLD=value
dnl     Pressure at or over threshold value is alarming
ifdef(`PRESSURE_THRESHOLD', `', `define(`PRESSURE_THRESHOLD', ifelse(PRESSURE_UNIT, `psi', 80, 5500))')dnl
dnl
dnl   -DTEMPERATURE_UNITS=units
dnl     Unit value (f or c) for temperature
ifdef(`TEMPERATURE_UNIT', `define(`TEMPERATURE_UNIT', translit(TEMPERATURE_UNIT, `A-Z', `a-z'))', `define(`TEMPERATURE_UNIT', `f')')dnl
dnl
dnl   -DTEMPERATURE_FORMAT=value
dnl     Format for temperature presentation
ifdef(`TEMPERATURE_FORMAT', `', `define(`TEMPERATURE_FORMAT', ifelse(TEMPERATURE_UNIT, `f', %.1f, %.2f))')dnl
dnl
dnl   -DTEMPERATURE_MINIMUM=value
dnl     Minimum pressure value supported by meter
ifdef(`TEMPERATURE_MINIMUM', `', `define(`TEMPERATURE_MINIMUM', ifelse(TEMPERATURE_UNIT, `f', 0, -20))')dnl
dnl
dnl   -DTEMPERATURE_MAXIMUM=value
dnl     Maximum pressure value supported by meter
ifdef(`TEMPERATURE_MAXIMUM', `', `define(`TEMPERATURE_MAXIMUM', ifelse(TEMPERATURE_UNIT, `f', 120, 50))')dnl
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

globals:
  - id: after_boot_
    type: bool
    initial_value: "false"
  - id: button_held_
    type: bool
    initial_value: "false"
  - id: light_brightness_target_
    type: float
    initial_value: "1.0f"
    restore_value: yes

esphome:
  <<: *m5stack_atoms3r_esphome
  name: NAME
  on_boot:
    globals.set:
      id: after_boot_
      value: "true"

esp32:
  <<: *m5stack_atoms3r_esp32
  framework:
    <<: *m5stack_atoms3r_esp32_framework
    sdkconfig_options:
      <<: *m5stack_atoms3r_esp32_framework_sdkconfig_options
      CONFIG_PARTITION_TABLE_OFFSET: "0xf000"
      CONFIG_SECURE_FLASH_ENC_ENABLED: "y"
      CONFIG_SECURE_FLASH_ENCRYPTION_AES256: "y"
      CONFIG_NVS_ENCRYPTION: "n"
      CONFIG_NVS_SEC_KEY_PROTECT_USING_FLASH_ENC: "n"
  partitions: partitions.csv

psram: *m5stack_atoms3r_psram

i2c:
  - *m5stack_atoms3r_i2c
  - <<: *m5stack_atoms3r_i2c_grove
    # replace internal pullups with external 4.7k pullups per TE M3200 datasheet
    scl_pullup_enabled: false
    sda_pullup_enabled: false

lp5562:
  <<: *m5stack_atoms3r_lp5562

output:
  <<: *m5stack_atoms3r_output

spi: *m5stack_atoms3r_spi

ethernet: *m5stack_atomic_poe_base_ethernet

light:
  # a completed turn_on action to brightness 0 will turn the light off but with brightness 1
  - <<: *m5stack_atoms3r_light
    id: light_
    restore_mode: RESTORE_DEFAULT_ON

binary_sensor:
  - <<: *m5stack_atoms3r_binary_sensor
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
          if:
            condition:
              light.is_off: light_
            then:
              globals.set:
                id: light_brightness_target_
                value: "1.0f"
            else:
              if:
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
    id: pressure_measurement_alarm_
    name: pressure measurement alarm
    restore_mode: RESTORE_DEFAULT_OFF
    optimistic: true`'dnl
ifdef(`_smtp_defined', `
    on_turn_off:
      if:
        condition:
          lambda: return id(after_boot_);
        then:
          smtp_.send:
            subject: !lambda return str_sprintf("apms pressure measurement success (now PRESSURE_FORMAT PRESSURE_UNIT)", id(pressure_`'PRESSURE_UNIT`'_).state);
    on_turn_on:
      if:
        condition:
          lambda: return id(after_boot_);
        then:
          smtp_.send:
            subject: !lambda return str_sprintf("apms pressure measurement failure (was PRESSURE_FORMAT PRESSURE_UNIT)", id(pressure_`'PRESSURE_UNIT`'_).state);')

  - platform: template
    id: pressure_threshold_alarm_
    name: pressure threshold alarm
    restore_mode: RESTORE_DEFAULT_OFF
    optimistic: true`'dnl
ifdef(`_smtp_defined', `
    on_turn_off:
      if:
        condition:
          lambda: return id(after_boot_);
        then:
          smtp_.send:
            subject: !lambda return str_sprintf("apms pressure (PRESSURE_FORMAT PRESSURE_UNIT) < PRESSURE_THRESHOLD", id(pressure_`'PRESSURE_UNIT`'_).state);
    on_turn_on:
      if:
        condition:
          lambda: return id(after_boot_);
        then:
          smtp_.send:
            subject: !lambda return str_sprintf("apms pressure (PRESSURE_FORMAT PRESSURE_UNIT) >= PRESSURE_THRESHOLD", id(pressure_`'PRESSURE_UNIT`'_).state);')

  - platform: template
    id: temperature_measurement_alarm_
    restore_mode: RESTORE_DEFAULT_OFF
    optimistic: true

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

    raw_pressure:
      id: pressure_
      internal: true
      on_value:
        if:
          condition:
            lambda: return std::isnan(x);
          then:
            - switch.turn_on: pressure_measurement_alarm_
            - lvgl.widget.hide: pressure_meter_
          else:
            - component.update: pressure_psi_
            - component.update: pressure_mbar_
            - switch.turn_off: pressure_measurement_alarm_
            - lvgl.widget.show: pressure_meter_
            - if:
                condition:
                  lambda: return id(pressure_`'PRESSURE_UNIT`'_).state < PRESSURE_THRESHOLD;
                then:
                  - logger.log:
                      level: INFO
                      format: "NAME pressure (PRESSURE_FORMAT PRESSURE_UNIT) < PRESSURE_THRESHOLD"
                      args: [id(pressure_`'PRESSURE_UNIT`'_).state]
                  - switch.turn_off: pressure_threshold_alarm_
                else:
                  - logger.log:
                      level: WARN
                      format: "NAME pressure (PRESSURE_FORMAT PRESSURE_UNIT) >= PRESSURE_THRESHOLD"
                      args: [id(pressure_`'PRESSURE_UNIT`'_).state]
                  - switch.turn_on: pressure_threshold_alarm_

    temperature:
      id: temperature_celsius_
      name: temperature celsius
      on_value:
        if:
          condition:
            lambda: return std::isnan(x);
          then:
            - switch.turn_on: temperature_measurement_alarm_
            - lvgl.widget.hide: temperature_meter_
          else:
            - component.update: temperature_fahrenheit_
            - switch.turn_off: temperature_measurement_alarm_
            - lvgl.widget.show: temperature_meter_`'dnl
  ifelse(TEMPERATURE_UNIT, `c', `
            - lvgl.indicator.update:
                id: temperature_indicator_
                value: !lambda return x;
            - lvgl.label.update:
                id: temperature_label_
                text: !lambda return str_sprintf("TEMPERATURE_FORMAT", x);')

  - platform: template
    id: temperature_fahrenheit_
    name: temperature fahrenheit
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
ifelse(TEMPERATURE_UNIT, `f', `
    on_value:
      - lvgl.indicator.update:
          id: temperature_indicator_
          value: !lambda return x;
      - lvgl.label.update:
          id: temperature_label_
          text: !lambda return str_sprintf("TEMPERATURE_FORMAT", x);')

  - platform: template
    id: pressure_psi_
    name: pressure psi
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
ifelse(PRESSURE_UNIT, `psi', `
    on_value:
      - lvgl.indicator.update:
          id: pressure_indicator_
          value: !lambda return x;
      - lvgl.label.update:
          id: pressure_label_
          text: !lambda return str_sprintf("PRESSURE_FORMAT", x);')

  - platform: template
    id: pressure_mbar_
    name: pressure mbar
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
ifelse(PRESSURE_UNIT, `mbar', `
    on_value:
      - lvgl.indicator.update:
          id: pressure_indicator_
          value: !lambda return x;
      - lvgl.label.update:
          id: pressure_label_
          text: !lambda return str_sprintf("PRESSURE_FORMAT", x);')

image:
  - id: apms_
    file: apms.png
    type: rgb565
    resize: M5STACK_ATOM_DISPLAY_SIZE
  - id: pressure_scale_
    file: scale_`'PRESSURE_UNIT.png
    type: rgb565
    resize: M5STACK_ATOM_DISPLAY_SIZE
    transparency: alpha_channel
  - id: temperature_scale_
    file: scale_`'TEMPERATURE_UNIT.png
    type: rgb565
    resize: M5STACK_ATOM_DISPLAY_SIZE
    transparency: alpha_channel

lvgl:
  pages:
    - widgets:
        - image:
            src: apms_
            align: CENTER
            on_boot:
              - delay: 4s
              - lvgl.page.next:
    - widgets:
        - container:
            widgets:
              - obj:
                  bg_color: black
                  width: 100%
                  height: 100%
                  border_width: 0
                  radius: 0
              - meter:
                  bg_opa: TRANSP
                  width: 100%
                  height: 100%
                  scales:
                    - range_from: PRESSURE_MINIMUM
                      range_to: PRESSURE_MAXIMUM
                      indicators:
                        - arc:
                            color: green
                            width: 8
                            start_value: PRESSURE_MINIMUM
                            end_value: PRESSURE_THRESHOLD
                        - arc:
                            color: red
                            width: 8
                            start_value: PRESSURE_THRESHOLD
                            end_value: PRESSURE_MAXIMUM
              - image:
                  src: pressure_scale_
                  align: CENTER
              - meter:
                  id: pressure_meter_
                  bg_opa: TRANSP
                  width: 100%
                  height: 100%
                  hidden: true
                  scales:
                    - range_from: PRESSURE_MINIMUM
                      range_to: PRESSURE_MAXIMUM
                      indicators:
                        - line:
                            id: pressure_indicator_
                            color: red
                            value: PRESSURE_THRESHOLD
              - label:
                  id: pressure_label_
                  align: CENTER
                  text_color: white
                  y: 45
                  text: "---"
    - widgets:
        - container:
            widgets:
              - obj:
                  bg_color: black
                  width: 100%
                  height: 100%
                  border_width: 0
                  radius: 0
              - image:
                  src: temperature_scale_
                  align: CENTER
              - meter:
                  id: temperature_meter_
                  bg_opa: TRANSP
                  width: 100%
                  height: 100%
                  hidden: true
                  scales:
                    - range_from: TEMPERATURE_MINIMUM
                      range_to: TEMPERATURE_MAXIMUM
                      indicators:
                        - line:
                            id: temperature_indicator_
                            color: red
                            value: eval((TEMPERATURE_MINIMUM + TEMPERATURE_MAXIMUM) / 2)
              - label:
                  id: temperature_label_
                  align: CENTER
                  text_color: white
                  y: 45
                  text: "--"
