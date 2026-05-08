define(`namespace', `m5stack_atomic_poe_base')dnl
dnl This YAML is not intended for direct consumption by esphome.
dnl Because its YAML parser does not support anchors and aliases
dnl between files using !include, we get that feature by including
dnl files using m4.
dnl For example,
dnl   m4 m5stack_atoms3r.yaml m5stack_atomic_poe_base.m4 example.m4 > example.yaml
dnl
dnl ESPHome support for M5Stack Atomic PoE Base
dnl   https://docs.m5stack.com/en/atom/Atomic%20PoE%20Base
dnl
dnl a top level key for this namespace is created
dnl with keys and anchored content values.
dnl in order to affect an ESPHome configuration,
dnl such content should be aliased elsewhere.
dnl this should be done selectively so that the configuration only has what is needed.
.namespace:

  ethernet: &namespace`'_ethernet
    interface: spi3
    type: W5500
    clk_pin: M5STACK_ATOM_BUS_1_01
    cs_pin: M5STACK_ATOM_BUS_1_02
    miso_pin: M5STACK_ATOM_BUS_1_03
    mosi_pin: M5STACK_ATOM_BUS_1_04

undefine(`namespace')dnl
