#pragma once

#include <array>
#include <optional>
#include <ranges>

#include "esphome/components/sensor/sensor.h"
#include "esphome/core/component.h"
#include "esphome/core/log.h"
#include "esphome/core/template_lambda.h"

namespace esphome {
namespace composition_ {

static constexpr auto TAG{"composition_"};

// CompositionSensor is like TemplateSensor but since TemplateSensor is final it cannot be one.
// Instead, CompositionSensor mirrors TemplateSensor's capabilities
// including having a (required) TemplateLambda that returns its value.
// The lambda composition should consume the CompositionSensor's curried arguments
// and is called to do when the last argument is curried.
template<std::size_t size> class CompositionSensor : public sensor::Sensor, public Component {
 public:
  // mirror TemplateSensor method
  template<typename F> void set_template(F &&f) { this->f_.set(std::forward<F>(f)); }

  void set_sensors(const std::array<sensor::Sensor *, size> &sensors) { this->sensors_ = sensors; }

  // mirror TemplateSensor method
  // and log size
  void dump_config() override {
    LOG_SENSOR("", "CompositionSensor", this);
    ESP_LOGCONFIG(TAG, "  size: %zu", size);
  }

  // mirror TemplateSensor method
  float get_setup_priority() const override { return setup_priority::HARDWARE; }

  // curry should be called as positional arguments become available.
  // when all arguments have been curried, the composition is performed.
  void curry(std::size_t ordinal, float value) {
    if (ordinal >= size) {
      ESP_LOGE(TAG, "curry(%zu, %.3f): ordinal out of range (>= %zu)", ordinal, value, size);
      return;
    }

    this->curried_[ordinal] = value;

    auto const count = std::ranges::count_if(this->curried_, [](const auto &o) { return o.has_value(); });
    ESP_LOGD(TAG, "curry(%zu, %.3f): %zu/%zu curried", ordinal, value, count, size);

    if (count == size) {
      if (!this->f_.has_value())
        return;
      auto val = this->f_();
      if (val.has_value()) {
        this->publish_state(*val);
      }
    }
  }

  // curry a value for one of our sensors
  void curry(sensor::Sensor *sensor, float value) {
    auto const it = std::ranges::find(this->sensors_, sensor);
    if (it != this->sensors_.end()) {
      this->curry(std::distance(this->sensors_.begin(), it), value);
    } else {
      ESP_LOGE(TAG, "curry(%p): unexpected sensor", sensor);
    }
  }

  // curry the state of one of our sensors
  void curry(sensor::Sensor *sensor) { this->curry(sensor, sensor->get_state()); }

  // consume the curried_ value
  std::array<std::optional<float>, size> consume() {
    ESP_LOGD(TAG, "consume");
    auto const copy = this->curried_;
    this->curried_.fill(std::nullopt);
    return copy;
  }

 protected:
  TemplateLambda<float> f_;

  std::array<sensor::Sensor *, size> sensors_{};

  std::array<std::optional<float>, size> curried_{};
};

}  // namespace composition_
}  // namespace esphome
