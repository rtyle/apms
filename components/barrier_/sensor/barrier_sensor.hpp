#pragma once

#include <array>
#include <optional>
#include <ranges>

#include "esphome/components/sensor/sensor.h"
#include "esphome/core/component.h"
#include "esphome/core/log.h"
#include "esphome/core/template_lambda.h"

namespace esphome {
namespace barrier_ {

static constexpr auto TAG{"barrier_"};

// TemplateSensor is final so we can't inherit from it
// but we can mirror it
template<std::size_t expected> class BarrierTemplateSensor : public sensor::Sensor, public PollingComponent {
 public:
  // mirror TemplateSensor method
  template<typename F> void set_template(F &&f) { this->f_.set(std::forward<F>(f)); }

  // mirror TemplateSensor method
  void update() override {
    if (!this->f_.has_value())
      return;
    auto val = this->f_();
    if (val.has_value()) {
      this->publish_state(*val);
    }
  }

  // mirror TemplateSensor method
  // and log expected value
  void dump_config() override {
    LOG_SENSOR("", "BarrierTemplate Sensor", this);
    LOG_UPDATE_INTERVAL(this);
    ESP_LOGCONFIG(TAG, "  Expected: %zu", expected);
  }

  // mirror TemplateSensor method
  float get_setup_priority() const override { return setup_priority::HARDWARE; }

  // called by contributors when they arrive at the barrier
  // ordinal is the contributor's index (0-based)
  // value is the value to contribute to the barrier
  void arrive(std::size_t ordinal, float value) {
    if (ordinal >= expected) {
      ESP_LOGE(TAG, "arrive(%zu, %.3f): ordinal out of range (expected < %zu)", ordinal, value, expected);
      return;
    }

    this->value_[ordinal] = value;
    ESP_LOGD(TAG, "arrive(%zu, %.3f): %zu/%zu contributions received", ordinal, value,
             std::ranges::count_if(this->value_, [](const auto &o) { return o.has_value(); }), expected);

    if (std::ranges::all_of(this->value_, &std::optional<float>::has_value)) {
      ESP_LOGD(TAG, "update");
      this->update();
    }
  }

  // consume the aggregate barrier value and reset it
  std::array<std::optional<float>, expected> join() {
    ESP_LOGD(TAG, "join");
    auto copy = this->value_;
    this->value_.fill(std::nullopt);
    return copy;
  }

 protected:
  TemplateLambda<float> f_;

  std::array<std::optional<float>, expected> value_{};
};

}  // namespace barrier_
}  // namespace esphome