import esphome.codegen as cg
import esphome.config_validation as cv
from esphome.components import sensor
from esphome.const import CONF_ID, CONF_LAMBDA, CONF_SIZE

from .. import composition_ns

CONF_SENSORS = "sensors"

CompositionSensor = composition_ns.class_(
    "CompositionSensor", sensor.Sensor, cg.Component
)

CONFIG_SCHEMA = sensor.sensor_schema(
    CompositionSensor,
    accuracy_decimals=1,
).extend(
    {
        cv.Exclusive(CONF_SIZE, "size_or_sensors"): cv.All(
            cv.positive_int,
            cv.Range(min=2, msg="size must be at least 2"),
        ),
        cv.Exclusive(CONF_SENSORS, "size_or_sensors"): cv.All(
            cv.ensure_list(cv.use_id(sensor.Sensor)),
            cv.Length(min=2),
        ),
        cv.Required(CONF_LAMBDA): cv.returning_lambda,
    }
)


def _get_size(config):
    if CONF_SENSORS in config:
        return len(config[CONF_SENSORS])
    return config[CONF_SIZE]


async def to_code(config):
    # size is a template parameter so this changes the configured type
    config[CONF_ID].type = composition_ns.class_(
        f"CompositionSensor<{_get_size(config)}>",
        sensor.Sensor,
        cg.Component,
    )
    composition = await sensor.new_sensor(config)
    await cg.register_component(composition, config)

    template_ = await cg.process_lambda(
        config[CONF_LAMBDA], [], return_type=cg.optional.template(float)
    )
    cg.add(composition.set_template(template_))

    if CONF_SENSORS in config:
        cg.add(
            composition.set_sensors(
                cg.ArrayInitializer(
                    *[await cg.get_variable(sensor) for sensor in config[CONF_SENSORS]]
                )
            )
        )
