#include "component.h"

#include <algorithm>
#include <fstream>
#include <limits>
#include <set>
#include <sstream>
#include <stdexcept>

#include "json.hpp"

namespace {

int decimal_integer(const std::string& token) {
    const auto start = token.find_first_not_of("+-");
    if (start == std::string::npos || start > 1 ||
        token.find_first_not_of("0123456789", start) != std::string::npos) {
        throw std::invalid_argument("Expected a decimal integer");
    }
    return std::stoi(token);
}

int integer_parameter(const nlohmann::json& layer, const char* name, int minimum = 1) {
    if (!layer.contains(name) || !layer.at(name).is_number_integer() ||
        layer.at(name) < minimum || layer.at(name) > std::numeric_limits<int>::max()) {
        throw std::invalid_argument(std::string(name) + " must be an integer >= " + std::to_string(minimum));
    }
    return layer.at(name).get<int>();
}

void validate_events(const std::vector<Event>& events) {
    if (events.empty()) {
        throw std::invalid_argument("The event frame is empty");
    }
    int previous = -1;
    for (std::size_t index = 0; index < events.size(); ++index) {
        const auto [row, column] = events[index].address;
        const auto context = "Event " + std::to_string(index + 1) + ": ";
        if (row < 0 || row >= kImageHeight || column < 0 || column >= kImageWidth) {
            throw std::invalid_argument(context + "coordinates exceed the C++ image dimensions");
        }
        const int address = row * kImageWidth + column;
        if (address < previous) {
            throw std::invalid_argument(context + "events must be in nondecreasing row-major order");
        }
        previous = address;
    }
}

}  // namespace

EventScheduler::EventScheduler(LayerConfig config)
    : config_(std::move(config)), half_kernel_(config_.kernel_size / 2) {
    if (config_.kernel_size <= 0 || config_.kernel_size % 2 == 0 ||
        config_.kernel_size > std::min(kImageWidth, kImageHeight) ||
        config_.data_width <= 0 || config_.compute_latency < 0) {
        throw std::invalid_argument("Invalid scheduler parameters: " + config_.name);
    }
    pending_.resize(static_cast<std::size_t>(config_.kernel_size));
}

int EventScheduler::absolute_address(std::pair<int, int> address) {
    return address.first * kImageWidth + address.second;
}

void EventScheduler::enqueue_windows() {
    const auto [row, column] = current_event_.address;
    const auto [previous_row, previous_column] = previous_event_.address;
    const bool full_window = row != previous_row || column >= previous_column + config_.kernel_size;
    const int start = full_window ? -half_kernel_ : half_kernel_ + 1 - (column - previous_column);
    for (int offset_column = start; offset_column <= half_kernel_; ++offset_column) {
        for (int offset_row = -half_kernel_; offset_row <= half_kernel_; ++offset_row) {
            pending_[offset_row + half_kernel_].emplace_back(row + offset_row, column + offset_column);
        }
    }
}

std::optional<int> EventScheduler::next_address() const {
    std::optional<int> minimum;
    for (const auto& queue : pending_) {
        if (!queue.empty()) {
            const int address = absolute_address(queue.front());
            if (!minimum || address < *minimum) {
                minimum = address;
            }
        }
    }
    return minimum;
}

void EventScheduler::remove_address(int address) {
    for (auto& queue : pending_) {
        if (!queue.empty() && absolute_address(queue.front()) == address) {
            queue.pop_front();
        }
    }
}

std::optional<Event> EventScheduler::step(std::optional<Event> input, bool ready) {
    switch (state_) {
    case SchedulerState::Update:
        if (input) {
            previous_event_ = current_event_;
            current_event_ = *input;
            enqueue_windows();
            state_ = SchedulerState::Compare;
        }
        break;
    case SchedulerState::Compare: {
        const auto address = next_address();
        // Preserve the centered-window readiness rule of the C++ research revision.
        const int ready_before = absolute_address(current_event_.address) - kImageWidth * half_kernel_ - half_kernel_;
        if (address && *address < ready_before) {
            output_address_ = *address;
            remove_address(*address);
            state_ = SchedulerState::Read;
            compute_done_ = false;
        } else {
            state_ = SchedulerState::Write;
            write_done_ = false;
            write_clock_ = 0;
            write_completed_ = false;
        }
        break;
    }
    case SchedulerState::Read:
        if (compute_done_) {
            if (ready) {
                state_ = SchedulerState::Compare;
                compute_done_ = false;
                // Integer division/remainder retain the original handling of border addresses.
                return Event{{output_address_ / kImageWidth, output_address_ % kImageWidth}, current_event_.value};
            }
        } else if (compute_clock_ < config_.compute_latency) {
            ++compute_clock_;
        } else {
            compute_clock_ = 0;
            compute_done_ = true;
        }
        break;
    case SchedulerState::Write:
        if (write_completed_) {
            state_ = SchedulerState::Update;
            write_completed_ = false;
            write_done_ = false;
        } else if (write_done_) {
            if (write_clock_ < 1) {
                ++write_clock_;
            } else {
                write_clock_ = 0;
                write_completed_ = true;
            }
        } else if (current_row_ < current_event_.address.first - config_.kernel_size + 1) {
            ++current_row_;
        } else {
            write_done_ = true;
        }
        break;
    }
    return std::nullopt;
}

std::vector<Event> load_events(const std::string& path) {
    std::ifstream file(path);
    if (!file) {
        throw std::runtime_error("Cannot open event file: " + path);
    }
    std::vector<Event> events;
    std::string line;
    std::size_t line_number = 0;
    while (std::getline(file, line)) {
        ++line_number;
        line = line.substr(0, line.find('#'));
        std::istringstream record(line);
        record >> std::ws;
        if (record.eof()) {
            continue;
        }
        Event event;
        std::string row, column, value, extra;
        try {
            if (!(record >> row >> column >> value) || (record >> extra)) {
                throw std::invalid_argument("Expected three fields");
            }
            event = {{decimal_integer(row), decimal_integer(column)}, decimal_integer(value)};
        } catch (const std::exception&) {
            throw std::invalid_argument(path + ":" + std::to_string(line_number) + ": expected three decimal integers");
        }
        events.push_back(event);
    }
    if (file.bad()) {
        throw std::runtime_error("Failed to read event file: " + path);
    }
    validate_events(events);
    return events;
}

Espresso::Espresso(const std::string& config_path) {
    std::ifstream file(config_path);
    if (!file) {
        throw std::runtime_error("Cannot open configuration: " + config_path);
    }
    std::vector<std::set<std::string>> object_keys;
    const auto unique_keys = [&object_keys](int, nlohmann::json::parse_event_t event, nlohmann::json& parsed) {
        using ParseEvent = nlohmann::json::parse_event_t;
        if (event == ParseEvent::object_start) {
            object_keys.emplace_back();
        } else if (event == ParseEvent::key) {
            const auto key = parsed.get<std::string>();
            if (!object_keys.back().insert(key).second) {
                throw std::invalid_argument("Duplicate configuration key: " + key);
            }
        } else if (event == ParseEvent::object_end) {
            object_keys.pop_back();
        }
        return true;
    };
    const auto config = nlohmann::json::parse(file, unique_keys);
    if (!config.is_object() || !config.contains("network") ||
        !config.at("network").is_object() || config.at("network").empty()) {
        throw std::invalid_argument("network must be a nonempty object");
    }
    // nlohmann::json uses ordered-by-key objects, matching the old std::map loader.
    for (const auto& [name, parameters] : config.at("network").items()) {
        if (name.empty() || !parameters.is_object()) {
            throw std::invalid_argument("Every layer needs a name and parameter object");
        }
        LayerConfig layer{name, integer_parameter(parameters, "kernelsize"),
                          integer_parameter(parameters, "datawidth"),
                          integer_parameter(parameters, "computelatency", 0)};
        EventScheduler validated(layer);
        layers_.push_back(std::move(layer));
    }
}

std::uint64_t Espresso::process_frame(const std::string& event_path) {
    return process_events(load_events(event_path));
}

std::uint64_t Espresso::process_events(const std::vector<Event>& events) {
    validate_events(events);
    // A model instance can process multiple independent frames without residual queues.
    std::vector<EventScheduler> stages;
    stages.reserve(layers_.size());
    for (const auto& layer : layers_) {
        stages.emplace_back(layer);
    }
    std::size_t event_index = 0;
    std::uint64_t cycles = 0;
    const auto active = [&stages] {
        return std::any_of(stages.begin(), stages.end(), [](const auto& stage) {
            return stage.state() != SchedulerState::Update;
        });
    };
    // End at idle after input exhaustion; no final padding/window flush is inserted.
    while (event_index < events.size() || active()) {
        ++cycles;
        std::optional<Event> forwarded;
        for (std::size_t index = 0; index < stages.size(); ++index) {
            auto& stage = stages[index];
            if (stage.state() == SchedulerState::Read) {
                const bool ready = index + 1 == stages.size() || stages[index + 1].state() == SchedulerState::Update;
                if (auto output = stage.step(std::nullopt, ready)) {
                    forwarded = output;
                }
            } else if (stage.state() == SchedulerState::Update) {
                if (index == 0) {
                    stage.step(event_index < events.size() ? std::optional<Event>(events[event_index++]) : std::nullopt);
                } else {
                    stage.step(forwarded);
                    forwarded.reset();
                }
            } else {
                stage.step();
            }
        }
    }
    return cycles;
}
