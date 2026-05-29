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
dnl   -DSMTP=value
dnl     Value is the name of the file that declares the smtp_ component
ifdef(`SMTP', `', `define(`SMTP', `smtp.m4')')dnl
dnl
dnl   -DPRESSURE_UNIT=value
dnl     Unit value (psi or mbar) for pressure
ifdef(`PRESSURE_UNIT', `define(`PRESSURE_UNIT', translit(PRESSURE_UNIT, `A-Z', `a-z'))', `define(`PRESSURE_UNIT', `psi')')dnl
dnl
dnl   -DTEMPERATURE_UNIT=value
dnl     Unit value (fahrenheit or celsius) for temperature
ifdef(`TEMPERATURE_UNIT', `define(`TEMPERATURE_UNIT', translit(TEMPERATURE_UNIT, `A-Z', `a-z'))', `define(`TEMPERATURE_UNIT', `fahrenheit')')dnl
dnl
---

include(m5stack_atoms3r.m4)dnl
include(m5stack_atomic_poe_base.m4)dnl
# only top level substitutions can be overridden on the esphome command line
substitutions:
  <<: *m5stack_atoms3r_substitutions
  name: NAME
  logger_level: INFO
  update_interval: 60

  pressure_raw_psi_0: 1000
  pressure_raw_psi_100: 15000

  pressure_unit: PRESSURE_UNIT

  pressure_psi_precision: 3
  pressure_psi_minimum: 0
  pressure_psi_maximum: 100
  pressure_psi_threshold: 80

  pressure_mbar_precision: 1
  pressure_mbar_minimum: 0
  pressure_mbar_maximum: 7000
  pressure_mbar_threshold: 5500
  pressure_mbar_barometric: 1013.25

  pressure_precision: ${pressure[pressure.unit].precision}
  pressure_minimum: ${pressure[pressure.unit].minimum}
  pressure_maximum: ${pressure[pressure.unit].maximum}
  pressure_threshold: ${pressure[pressure.unit].threshold}

  pressure_format: "%.${pressure_precision}f"
  pressure_state: id(pressure_${pressure.unit}_).state

  temperature_unit: TEMPERATURE_UNIT

  temperature_fahrenheit_precision: 1
  temperature_fahrenheit_minimum: 0
  temperature_fahrenheit_maximum: 120

  temperature_celsius_precision: 1
  temperature_celsius_minimum: -20
  temperature_celsius_maximum: 50

  temperature_precision: ${temperature[temperature.unit].precision}
  temperature_minimum: ${temperature[temperature.unit].minimum}
  temperature_maximum: ${temperature[temperature.unit].maximum}

  temperature_format: "%.${temperature_precision}f"

  molar_density_precision: 1
  molar_density_minimum: 0
  molar_density_maximum: 400

  pressure:
    raw:
      psi_0: ${pressure_raw_psi_0}
      psi_100: ${pressure_raw_psi_100}
    unit: ${pressure_unit}
    psi:
      precision: ${pressure_psi_precision}
      minimum: ${pressure_psi_minimum}
      maximum: ${pressure_psi_maximum}
      threshold: ${pressure_psi_threshold}
    mbar:
      precision: ${pressure_mbar_precision}
      minimum: ${pressure_mbar_minimum}
      maximum: ${pressure_mbar_maximum}
      threshold: ${pressure_mbar_threshold}
      barometric: ${pressure_mbar_barometric}
  temperature:
    unit: ${temperature_unit}
    fahrenheit:
      precision: ${temperature_fahrenheit_precision}
      minimum: ${temperature_fahrenheit_minimum}
      maximum: ${temperature_fahrenheit_maximum}
    celsius:
      precision: ${temperature_celsius_precision}
      minimum: ${temperature_celsius_minimum}
      maximum: ${temperature_celsius_maximum}
  molar_density:
    precision: ${molar_density_precision}
    minimum: ${molar_density_minimum}
    maximum: ${molar_density_maximum}
    format: "%.${molar_density_precision}f"
  
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
  level: ${logger_level}

ota:
  - platform: esphome
    password: !secret NAME-ota-password

api:
  reboot_timeout: 0s
  encryption:
    key: !secret NAME-api-encryption-key

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
  name: ${name}
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

lp5562: *m5stack_atoms3r_lp5562

output:
  - *m5stack_atoms3r_output

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
        subject: !lambda return str_sprintf("${name} pressure (${pressure_format} ${pressure.unit}) >= ${pressure_threshold}", ${pressure_state});
    on_release:
      smtp_.send:
        subject: !lambda return str_sprintf("${name} pressure (${pressure_format} ${pressure.unit}) < ${pressure_threshold}", ${pressure_state});
')dnl

  - id: pressure_measurement_alarm_
    name: pressure measurement alarm
    platform: template
    device_class: problem
    trigger_on_initial_state: true
ifdef(`_smtp_defined', `dnl
    on_press:
      smtp_.send:
        subject: !lambda return str_sprintf("${name} pressure measurement failure (was ${pressure_format} ${pressure.unit})", ${pressure_state});
    on_release:
      smtp_.send:
        subject: !lambda return str_sprintf("${name} pressure measurement success (now ${pressure_format} ${pressure.unit})", ${pressure_state});
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
      - delay: ${update_interval +10}s
      - logger.log:
          level: ERROR
          format: "${name} pressure measurement failure (was ${pressure_format} ${pressure.unit})"
          args: ["${pressure_state}"]
      - binary_sensor.template.publish:
          id: pressure_measurement_alarm_
          state: ON
      - lvgl.widget.hide: pressure_meter_
      - lvgl.widget.hide: temperature_meter_
      - lvgl.widget.hide: molar_density_meter_

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
    update_interval: "${update_interval}s"

    raw_pressure:
      id: pressure_
      internal: true
      on_value:
        - component.update: pressure_psi_
        - component.update: pressure_mbar_
        # TEM3200Component::update calls, in order
        #   1. this-temperature_sensor_->publish_state(temperature);
        #   2. this->raw_pressure_sensor_->publish_state(raw_pressure);
        # now (2) we can update density from raw_pressure and temperature
        - component.update: molar_density_
define(`_pressure_unit_on_value', `dnl
    on_value:
      - binary_sensor.template.publish:
          id: pressure_measurement_alarm_
          state: OFF
      - script.execute: pressure_measurement_watchdog_
      - if:
          condition:
            lambda: return x < ${pressure_threshold};
          then:
            - logger.log:
                level: INFO
                format: "${name} pressure (${pressure_format} ${pressure.unit}) < ${pressure_threshold}"
                args: [x]
            - binary_sensor.template.publish:
                id: pressure_threshold_alarm_
                state: OFF
          else:
            - logger.log:
                level: WARN
                format: "${name} pressure (${pressure_format} ${pressure.unit}) >= ${pressure_threshold}"
                args: [x]
            - binary_sensor.template.publish:
                id: pressure_threshold_alarm_
                state: ON
      - lvgl.indicator.update:
          id: pressure_indicator_
          value: !lambda return x * ${math.pow(10, pressure_precision)};
      - lvgl.widget.show: pressure_meter_
      - lvgl.label.update:
          id: pressure_label_`'dnl
ifelse(PRESSURE_UNIT, `psi', `
          text: !lambda return str_sprintf("${pressure_format}", x);', `
          # pressure meter scale_mbar.png unit is BAR, adjust pressure_label_ text to match
          text: !lambda return str_sprintf("`%.'${pressure.mbar.precision + 3}`f'", x / ${math.pow(10, 3)});')
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
          value: !lambda return x * ${math.pow(10, ${temperature_precision})};
      - lvgl.widget.show: temperature_meter_
      - lvgl.label.update:
          id: temperature_label_
          text: !lambda return str_sprintf("${temperature_format}", x);
')dnl

  - platform: template
    id: pressure_psi_
    name: pressure psi
    update_interval: never
    unit_of_measurement: psi
    state_class: measurement
    device_class: pressure
    accuracy_decimals: ${pressure.psi.precision}
    lambda: |-
      return id(pressure_).state;
    filters:
      - calibrate_linear:
          - ${pressure.raw.psi_0} -> 0
          - ${pressure.raw.psi_100} -> 100
ifelse(PRESSURE_UNIT, `psi', _pressure_unit_on_value)dnl

  - platform: template
    id: pressure_mbar_
    name: pressure mbar
    update_interval: never
    unit_of_measurement: mbar
    state_class: measurement
    device_class: pressure
    accuracy_decimals: ${pressure.mbar.precision}
    lambda: |-
      return id(pressure_).state;
    filters:
      - calibrate_linear:
          - ${pressure.raw.psi_0} -> 0
          - ${pressure.raw.psi_100} -> 6894.76
ifelse(PRESSURE_UNIT, `mbar', _pressure_unit_on_value)dnl

  - platform: template
    id: temperature_celsius_
    name: temperature celsius
    update_interval: never
    unit_of_measurement: °C
    state_class: measurement
    device_class: temperature
    accuracy_decimals: ${temperature.celsius.precision}
    lambda: |-
      return id(temperature_).state;
ifelse(TEMPERATURE_UNIT, `celsius', _temperature_unit_on_value)dnl

  - platform: template
    id: temperature_fahrenheit_
    name: temperature fahrenheit
    update_interval: never
    unit_of_measurement: °F
    state_class: measurement
    device_class: temperature
    accuracy_decimals: ${temperature.fahrenheit.precision}
    lambda: |-
      return id(temperature_).state;
    filters:
      - calibrate_linear:
          - 0 -> 32
          - 100 -> 212
ifelse(TEMPERATURE_UNIT, `fahrenheit', _temperature_unit_on_value)dnl

  - platform: template
    id: molar_density_
    name: molar density
    update_interval: never
    unit_of_measurement: mol/m³
    state_class: measurement
    device_class: ""
    accuracy_decimals: ${molar_density.precision}
    # PV = nRT ⇒ n/V (molar density) = P/(R·T)
    # P is absolute pressure (TE M3200 gauge pressure + barometric pressure)
    # P in Pa = kg/(m·s²) (1 = 100 Pa/mbar)
    # V in m³
    # n in mol
    # R in kg·m²/(s²·mol·K) (constant = 8.31446)
    # T in kelvin (273.15 K = 0 °C)
    lambda: |-
      return (100.0f * (id(pressure_mbar_).state + ${pressure.mbar.barometric})) / (8.31446f * (id(temperature_).state + 273.15f));
    on_value:
      - logger.log:
          level: INFO
          format: "${name} molar_density ${molar_density.format} mol/m³"
          args: [x]
      - lvgl.indicator.update:
          id: molar_density_indicator_
          value: !lambda return x * ${math.pow(10, ${molar_density_precision})};
      - lvgl.widget.show: molar_density_meter_
      - lvgl.label.update:
          id: molar_density_label_
          text: !lambda return str_sprintf("${molar_density.format}", x);

image:
  - id: apms_
    file: apms.png
    type: rgb565
    resize: ${m5stack_atoms3r.display.size}
  - id: pressure_scale_
    file: scale_${pressure.unit}.png
    type: rgb565
    resize: ${m5stack_atoms3r.display.size}
    transparency: alpha_channel
  - id: temperature_scale_
    file: scale_${temperature.unit}.png
    type: rgb565
    resize: ${m5stack_atoms3r.display.size}
    transparency: alpha_channel
  - id: molar_density_scale_
    file: scale_molar_density.png
    type: rgb565
    resize: ${m5stack_atoms3r.display.size}
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
                    - range_from: ${pressure_minimum}
                      range_to: ${pressure_maximum}
                      indicators:
                        - arc:
                            color: green
                            width: 8
                            start_value: ${pressure_minimum}
                            end_value: ${pressure_threshold}
                        - arc:
                            color: red
                            width: 8
                            start_value: ${pressure_threshold}
                            end_value: ${pressure_maximum}
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
                    - range_from: ${math.pow(10, pressure_precision) * pressure_minimum}
                      range_to: ${math.pow(10, pressure_precision) * pressure_maximum}
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
                    - range_from: ${math.pow(10, temperature_precision) * temperature_minimum}
                      range_to: ${math.pow(10, temperature_precision) * temperature_maximum}
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
                  src: molar_density_scale_
                  align: CENTER
              - meter:
                  id: molar_density_meter_
                  bg_opa: TRANSP
                  width: 100%
                  height: 100%
                  hidden: true
                  scales:
                    - range_from: ${math.pow(10, molar_density.precision) * molar_density.minimum}
                      range_to: ${math.pow(10, molar_density.precision) * molar_density.maximum}
                      indicators:
                        - line:
                            id: molar_density_indicator_
                            color: red
              - label:
                  id: molar_density_label_
                  align: CENTER
                  text_color: white
                  y: 45
                  text: "--"
