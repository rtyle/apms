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
dnl   -DUPDATE_INTERVAL=value
dnl     Value (in seconds) of the update_interval key of the tem3200 component.
ifdef(`UPDATE_INTERVAL', `', `define(`UPDATE_INTERVAL', `60')')dnl
dnl
dnl   -DSMTP=value
dnl     Value is the name of the file that declares the smtp_ component
ifdef(`SMTP', `', `define(`SMTP', `smtp.m4')')dnl
dnl
dnl   -DRAW_PRESSURE_PSI_0=value
dnl     tem3200 raw_pressure value that maps to 0 psi
ifdef(`RAW_PRESSURE_PSI_0', `', `define(`RAW_PRESSURE_PSI_0', 1000)')dnl
dnl
dnl   -DRAW_PRESSURE_PSI_100=value
dnl     tem3200 raw_pressure value that maps to 100 psi
ifdef(`RAW_PRESSURE_PSI_100', `', `define(`RAW_PRESSURE_PSI_100', 15000)')dnl
dnl
dnl   -DPRESSURE_PRECISION_PSI=value
dnl     Number of digits after the decimal point for pressure in units of psi
ifdef(`PRESSURE_PRECISION_PSI', `', `define(`PRESSURE_PRECISION_PSI', 3)')dnl
dnl
dnl   -DPRESSURE_PRECISION_MBAR=value
dnl     Number of digits after the decimal point for pressure in units of mbar
ifdef(`PRESSURE_PRECISION_MBAR', `', `define(`PRESSURE_PRECISION_MBAR', 1)')dnl
dnl
dnl   -DPRESSURE_UNIT=value
dnl     Unit value (psi or mbar) for pressure
ifdef(`PRESSURE_UNIT', `define(`PRESSURE_UNIT', translit(PRESSURE_UNIT, `A-Z', `a-z'))', `define(`PRESSURE_UNIT', `psi')')dnl
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
dnl   -DTEMPERATURE_PRECISION_FAHRENHEIT=value
dnl     Number of digits after the decimal point for temperature in units of degrees fahrenheit
ifdef(`TEMPERATURE_PRECISION_FAHRENHEIT', `', `define(`TEMPERATURE_PRECISION_FAHRENHEIT', 1)')dnl
dnl
dnl   -DTEMPERATURE_PRECISION_CELSIUS=value
dnl     Number of digits after the decimal point for temperature in units of degrees celsius
ifdef(`TEMPERATURE_PRECISION_CELSIUS', `', `define(`TEMPERATURE_PRECISION_CELSIUS', 1)')dnl
dnl
dnl   -DTEMPERATURE_UNIT=value
dnl     Unit value (fahrenheit or celsius) for temperature
ifdef(`TEMPERATURE_UNIT', `define(`TEMPERATURE_UNIT', translit(TEMPERATURE_UNIT, `A-Z', `a-z'))', `define(`TEMPERATURE_UNIT', `fahrenheit')')dnl
dnl
dnl   -DTEMPERATURE_MINIMUM=value
dnl     Minimum pressure value supported by meter
ifdef(`TEMPERATURE_MINIMUM', `', `define(`TEMPERATURE_MINIMUM', ifelse(TEMPERATURE_UNIT, `fahrenheit', 0, -20))')dnl
dnl
dnl   -DTEMPERATURE_MAXIMUM=value
dnl     Maximum pressure value supported by meter
ifdef(`TEMPERATURE_MAXIMUM', `', `define(`TEMPERATURE_MAXIMUM', ifelse(TEMPERATURE_UNIT, `fahrenheit', 120, 50))')dnl
dnl
define(`_pressure_state', `id(pressure_'PRESSURE_UNIT`_).state')dnl
dnl
define(`_pressure_precision', indir(`PRESSURE_PRECISION_'ifelse(PRESSURE_UNIT, `psi', PSI, MBAR)))dnl
define(`_pressure_format', `%.'_pressure_precision`f')dnl
dnl
define(`_temperature_precision', indir(`TEMPERATURE_PRECISION_'ifelse(TEMPERATURE_UNIT, `fahrenheit', FAHRENHEIT, CELSIUS)))dnl
define(`_temperature_format', `%.'_temperature_precision`f')dnl
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
    script.execute: pressure_measurement_watchdog_

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

  - id: pressure_threshold_alarm_
    name: pressure threshold alarm
    platform: template
    device_class: problem
    trigger_on_initial_state: true
ifdef(`_smtp_defined', `dnl
    on_press:
      smtp_.send:
        subject: !lambda return str_sprintf("NAME pressure (_pressure_format PRESSURE_UNIT) >= PRESSURE_THRESHOLD", _pressure_state);
    on_release:
      smtp_.send:
        subject: !lambda return str_sprintf("NAME pressure (_pressure_format PRESSURE_UNIT) < PRESSURE_THRESHOLD", _pressure_state);
')dnl

  - id: pressure_measurement_alarm_
    name: pressure measurement alarm
    platform: template
    device_class: problem
    trigger_on_initial_state: true
ifdef(`_smtp_defined', `dnl
    on_press:
      smtp_.send:
        subject: !lambda return str_sprintf("NAME pressure measurement failure (was _pressure_format PRESSURE_UNIT)", _pressure_state);
    on_release:
      smtp_.send:
        subject: !lambda return str_sprintf("NAME pressure measurement success (now _pressure_format PRESSURE_UNIT)", _pressure_state);
')dnl

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

script:
  - id: pressure_measurement_watchdog_
    mode: restart
    then:
      - delay: eval(UPDATE_INTERVAL + 10)s
      - logger.log:
          level: ERROR
          format: "NAME pressure measurement failure (was _pressure_format PRESSURE_UNIT)"
          args: [_pressure_state]
      - binary_sensor.template.publish:
          id: pressure_measurement_alarm_
          state: ON
      - lvgl.widget.hide: pressure_meter_
      - lvgl.widget.hide: temperature_meter_

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
    update_interval: UPDATE_INTERVAL`'s

    raw_pressure:
      id: pressure_
      internal: true
      on_value:
        - component.update: pressure_psi_
        - component.update: pressure_mbar_
define(`_pressure_unit_on_value', `dnl
    on_value:
      - binary_sensor.template.publish:
          id: pressure_measurement_alarm_
          state: OFF
      - script.execute: pressure_measurement_watchdog_
      - if:
          condition:
            lambda: return x < PRESSURE_THRESHOLD;
          then:
            - logger.log:
                level: INFO
                format: "NAME pressure (_pressure_format PRESSURE_UNIT) < PRESSURE_THRESHOLD"
                args: [x]
            - binary_sensor.template.publish:
                id: pressure_threshold_alarm_
                state: OFF
          else:
            - logger.log:
                level: WARN
                format: "NAME pressure (_pressure_format PRESSURE_UNIT) >= PRESSURE_THRESHOLD"
                args: [x]
            - binary_sensor.template.publish:
                id: pressure_threshold_alarm_
                state: ON
      - lvgl.indicator.update:
          id: pressure_indicator_
          value: !lambda return x * eval(10**_pressure_precision);
      - lvgl.widget.show: pressure_meter_
      - lvgl.label.update:
          id: pressure_label_`'dnl
ifelse(PRESSURE_UNIT, `psi', `
          text: !lambda return str_sprintf("_pressure_format", x);', `
          # pressure_meter_ scale_mbar.png units are bar, adjust pressure_label_ text to match
          text: !lambda return str_sprintf("`%.'eval(PRESSURE_PRECISION_MBAR + 3)`f'", x / eval(10**3));')
')dnl

    temperature:
      id: temperature_
      internal: true
      on_value:
        - component.update: temperature_celsius_
        - component.update: temperature_fahrenheit_
define(`_temperature_unit_on_value', `dnl
    on_value:
      - lvgl.indicator.update:
          id: temperature_indicator_
          value: !lambda return x * eval(10**_temperature_precision);
      - lvgl.widget.show: temperature_meter_
      - lvgl.label.update:
          id: temperature_label_
          text: !lambda return str_sprintf("_temperature_format", x);
')dnl

  - platform: template
    id: pressure_psi_
    name: pressure psi
    update_interval: never
    unit_of_measurement: psi
    state_class: measurement
    device_class: pressure
    accuracy_decimals: PRESSURE_PRECISION_PSI
    lambda: |-
      return id(pressure_).state;
    filters:
      - calibrate_linear:
          - RAW_PRESSURE_PSI_0 -> 0
          - RAW_PRESSURE_PSI_100 -> 100
ifelse(PRESSURE_UNIT, `psi', _pressure_unit_on_value)dnl

  - platform: template
    id: pressure_mbar_
    name: pressure mbar
    update_interval: never
    unit_of_measurement: mbar
    state_class: measurement
    device_class: pressure
    accuracy_decimals: PRESSURE_PRECISION_MBAR
    lambda: |-
      return id(pressure_).state;
    filters:
      - calibrate_linear:
          - RAW_PRESSURE_PSI_0 -> 0
          - RAW_PRESSURE_PSI_100 -> 6894.76
ifelse(PRESSURE_UNIT, `mbar', _pressure_unit_on_value)dnl

  - platform: template
    id: temperature_celsius_
    name: temperature celsius
    update_interval: never
    unit_of_measurement: °C
    state_class: measurement
    device_class: temperature
    accuracy_decimals: TEMPERATURE_PRECISION_CELSIUS
    lambda: |-
      return id(temperature_).state;
ifelse(TEMPERATURE_UNIT, `fahrenheit', `', _temperature_unit_on_value)dnl

  - platform: template
    id: temperature_fahrenheit_
    name: temperature fahrenheit
    update_interval: never
    unit_of_measurement: °F
    state_class: measurement
    device_class: temperature
    accuracy_decimals: TEMPERATURE_PRECISION_FAHRENHEIT
    lambda: |-
      return id(temperature_).state;
    filters:
      - calibrate_linear:
          - 0 -> 32
          - 100 -> 212
ifelse(TEMPERATURE_UNIT, `fahrenheit', _temperature_unit_on_value)dnl

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
                    - range_from: eval(10**_pressure_precision * PRESSURE_MINIMUM)
                      range_to: eval(10**_pressure_precision * PRESSURE_MAXIMUM)
                      indicators:
                        - line:
                            id: pressure_indicator_
                            color: red
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
                    - range_from: eval(10**_temperature_precision * TEMPERATURE_MINIMUM)
                      range_to: eval(10**_temperature_precision * TEMPERATURE_MAXIMUM)
                      indicators:
                        - line:
                            id: temperature_indicator_
                            color: red
              - label:
                  id: temperature_label_
                  align: CENTER
                  text_color: white
                  y: 45
                  text: "--"
