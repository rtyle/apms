import esphome.codegen as cg
import esphome.config_validation as cv
from esphome.components import sensor
from esphome.const import CONF_ID, CONF_LAMBDA

from .. import barrier_ns

CONF_EXPECTED = "expected"

BarrierTemplateSensor = barrier_ns.class_(
    "BarrierTemplateSensor", sensor.Sensor, cg.PollingComponent
)

CONFIG_SCHEMA = (
    sensor.sensor_schema(
        BarrierTemplateSensor,
        accuracy_decimals=1,
    )
    .extend(
        {
            cv.Required(CONF_EXPECTED): cv.All(
                cv.positive_int,
                cv.Range(min=2, msg="expected must be at least 2"),
            ),
            cv.Required(CONF_LAMBDA): cv.returning_lambda,
        }
    )
    .extend(cv.polling_component_schema("never"))
)


async def to_code(config):
    # expected is a template parameter so this changes the configured type
    config[CONF_ID].type = barrier_ns.class_(
        f"BarrierTemplateSensor<{config[CONF_EXPECTED]}>",
        sensor.Sensor,
        cg.PollingComponent,
    )
    var = cg.new_Pvariable(config[CONF_ID])
    await cg.register_component(var, config)
    await sensor.register_sensor(var, config)

    template_ = await cg.process_lambda(
        config[CONF_LAMBDA], [], return_type=cg.optional.template(float)
    )
    cg.add(var.set_template(template_))
