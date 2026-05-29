define(`namespace', `m5stack_atoms3r')dnl
dnl This YAML is not intended for direct consumption by esphome.
dnl Because its YAML parser does not support anchors and aliases
dnl between files using !include, we get that feature by including
dnl files using m4.
dnl For example,
dnl   m4 m5stack_atoms3r.m4 example.m4 > example.yaml
dnl
dnl ESPHome support for M5Stack AtomS3R devices
dnl   https://docs.m5stack.com/en/core/AtomS3R
dnl
dnl a top level key for this namespace is created
dnl with keys and anchored content values.
dnl in order to affect an ESPHome configuration,
dnl such content should be aliased elsewhere.
dnl this should be done selectively so that the configuration only has what is needed.
dnl
dnl content is inspired from
dnl   https://docs.m5stack.com/en/homeassistant/voice_assistant/atoms3r_with_atomic_echo_base_voice_assistant
dnl   https://github.com/m5stack/esphome-yaml/blob/main/common/atoms3r-with-echo-base.yaml
.namespace:

  substitutions: &namespace`'_substitutions
    namespace:
      display:
        width: 128
        height: 128
        size: "128x128"
      gpio:
        button: GPIO41
        i2c:
          scl: GPIO0
          sda: GPIO45
        grove:
          _0: GPIO1
          _1: GPIO2
        spi:
          clk: GPIO15
          mosi: GPIO21
        ir: GPIO47
        display:
          dc: GPIO42
          reset: GPIO48
          cs: GPIO14
    m5stack_atom_bus:
      _0:
        _0: GPIO39
        _1: GPIO38
      _1:
        _1: GPIO5
        _2: GPIO6
        _3: GPIO7
        _4: GPIO8

  external_components: 
    - &namespace`'_external_components
      source: github://m5stack/esphome-yaml/components@main
      components: [lp5562]

  esphome: &namespace`'_esphome {}

  esp32:
    - &namespace`'_esp32
      board: esp32-s3-devkitc-1
      variant: esp32s3
      flash_size: 8MB
      cpu_frequency: 240Mhz
    - framework: &namespace`'_esp32_framework
        type: esp-idf
    - framework_sdkconfig_options: &namespace`'_esp32_framework_sdkconfig_options
          CONFIG_ESP32S3_DATA_CACHE_64KB: "y"
          CONFIG_ESP32S3_DATA_CACHE_LINE_64B: "y"

  psram: &namespace`'_psram
    mode: octal
    speed: 80MHz

  binary_sensor:
    - &namespace`'_binary_sensor
      platform: gpio
      id: namespace`'_button
      pin:
        number: ${namespace.gpio.button}
        mode: INPUT_PULLUP
        inverted: true
      internal: true

  i2c:
    - &namespace`'_i2c
      id: namespace`'_i2c
      scl:
        number: ${namespace.gpio.i2c.scl}
        ignore_strapping_warning: true
      sda:
        number: ${namespace.gpio.i2c.sda}
        ignore_strapping_warning: true
      scan: true
    - &namespace`'_i2c_grove
      id: namespace`'_i2c_grove
      scl: ${namespace.gpio.grove._0}
      sda: ${namespace.gpio.grove._1}
      scan: true

  lp5562: &namespace`'_lp5562
    id: namespace`'_lp5562
    i2c_id: namespace`'_i2c
    use_internal_clk: true
    high_pwm_freq: true
    logarithmic_dimming: true
    white_current: 17.5

  output:
    - &namespace`'_output
      platform: lp5562
      id: namespace`'_output
      lp5562_id: namespace`'_lp5562
      channel: white

  light:
    - &namespace`'_light
      platform: monochromatic
      output: namespace`'_output

  spi: &namespace`'_spi
    id: namespace`'_spi
    interface: spi2
    clk_pin: ${namespace.gpio.spi.clk}
    mosi_pin: ${namespace.gpio.spi.mosi}

  display:
    - &namespace`'_display
      platform: mipi_spi
      model: ST7789V
      dc_pin: ${namespace.gpio.display.dc}
      reset_pin: ${namespace.gpio.display.reset}
      cs_pin: ${namespace.gpio.display.cs}
      data_rate: 40MHz
      dimensions:
        width: ${namespace.display.width}
        height: ${namespace.display.height}
        offset_height: 1
        offset_width: 2
      invert_colors: true

undefine(`namespace')dnl
