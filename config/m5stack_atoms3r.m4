define(`namespace', `m5stack_atoms3r')dnl
define(`NAMESPACE', `M5STACK_ATOMS3R')dnl
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
dnl
dnl define internal GPIO pins
define(NAMESPACE`'_I2C_SCL, GPIO0)dnl
define(NAMESPACE`'_I2C_SDA, GPIO45)dnl
define(NAMESPACE`'_BUTTON, GPIO41)dnl
define(NAMESPACE`'_IR, GPIO47)dnl
define(NAMESPACE`'_SPI_CLK, GPIO15)dnl
define(NAMESPACE`'_SPI_MOSI, GPIO21)dnl
define(NAMESPACE`'_DISPLAY_DC, GPIO42)dnl
define(NAMESPACE`'_DISPLAY_RESET, GPIO48)dnl
define(NAMESPACE`'_DISPLAY_CS, GPIO14)dnl
dnl
dnl define external GPIO pins on the AtomS3R's Atom-Bus
define(M5STACK_ATOM_BUS_0_00, GPIO39)dnl
define(M5STACK_ATOM_BUS_0_01, GPIO38)dnl
define(M5STACK_ATOM_BUS_0_02, 5V)dnl
define(M5STACK_ATOM_BUS_0_03, GND)dnl
dnl
define(M5STACK_ATOM_BUS_1_00, 3V3)dnl
define(M5STACK_ATOM_BUS_1_01, GPIO5)dnl
define(M5STACK_ATOM_BUS_1_02, GPIO6)dnl
define(M5STACK_ATOM_BUS_1_03, GPIO7)dnl
define(M5STACK_ATOM_BUS_1_04, GPIO8)dnl
.namespace:

  external_components: &namespace`'_external_components
    source: github://m5stack/esphome-yaml/components@main
    components: [lp5562]

  esphome: &namespace`'_esphome {}

  esp32: &namespace`'_esp32
    board: esp32-s3-devkitc-1
    variant: esp32s3
    flash_size: 8MB
    cpu_frequency: 240Mhz
    framework:
      type: esp-idf
      sdkconfig_options:
        CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240: "y"
        CONFIG_ESP32S3_DATA_CACHE_64KB: "y"
        CONFIG_ESP32S3_DATA_CACHE_LINE_64B: "y"

  psram: &namespace`'_psram
    mode: octal
    speed: 80MHz

  binary_sensor: &namespace`'_binary_sensor
    - platform: gpio
      id: namespace`'_button
      pin:
        number: indir(NAMESPACE`'_BUTTON)
        mode: INPUT_PULLUP
        inverted: true
      internal: true

  i2c: &namespace`'_i2c
    id: i2c_
    scl:
      number: indir(NAMESPACE`'_I2C_SCL)
      ignore_strapping_warning: true
    sda:
      number: indir(NAMESPACE`'_I2C_SDA)
    scan: true

  lp5562: &namespace`'_lp5562
    id: namespace`'_lp5562
    i2c_id: i2c_
    use_internal_clk: true
    # power_save_mode: true
    # high_pwm_freq: true
    # logarithmic_dimming: true
    white_current: 17.5

  output: &namespace`'_output
    - platform: lp5562
      id: namespace`'_output
      lp5562_id: namespace`'_lp5562
      channel: white

  light: &namespace`'_light
    - platform: monochromatic
      output: namespace`'_output
      restore_mode: RESTORE_DEFAULT_ON

  spi: &namespace`'_spi
    id: spi_
    interface: spi2
    clk_pin: indir(NAMESPACE`'_SPI_CLK)
    mosi_pin: indir(NAMESPACE`'_SPI_MOSI)

  display: &namespace`'_display
    - platform: mipi_spi
      model: ST7789V
      dc_pin: indir(NAMESPACE`'_DISPLAY_DC)
      reset_pin: indir(NAMESPACE`'_DISPLAY_RESET)
      cs_pin: indir(NAMESPACE`'_DISPLAY_CS)
      data_rate: 40MHz
      dimensions:
        height: 128
        width: 128
        offset_width: 2
        offset_height: 1
      invert_colors: true

undefine(`namespace')dnl
undefine(`NAMESPACE')dnl
