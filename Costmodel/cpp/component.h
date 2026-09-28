#ifndef ESPRESSO_COMPONENT_H
#define ESPRESSO_COMPONENT_H

#include <cstdint>
#include <deque>
#include <optional>
#include <string>
#include <utility>
#include <vector>

// Dimensions of the historical C++ model, independent of the Python JSON schema.
inline constexpr int kImageWidth = 256;
inline constexpr int kImageHeight = 300;

struct Event {
    std::pair<int, int> address{0, 0};  // row, column
    int value = 0;
};

struct LayerConfig {
    std::string name;
    int kernel_size;
    int data_width;
    int compute_latency;
};

enum class SchedulerState { Update, Compare, Read, Write };

class EventScheduler {
public:
    explicit EventScheduler(LayerConfig config);
    SchedulerState state() const noexcept { return state_; }

    // Advance one clock. An output is returned only on a ready handshake.
    std::optional<Event> step(std::optional<Event> input = std::nullopt, bool ready = false);

private:
    static int absolute_address(std::pair<int, int> address);
    void enqueue_windows();
    std::optional<int> next_address() const;
    void remove_address(int address);

    LayerConfig config_;
    int half_kernel_;
    std::vector<std::deque<std::pair<int, int>>> pending_;
    SchedulerState state_ = SchedulerState::Update;
    Event current_event_;
    Event previous_event_;
    int output_address_ = 0;
    int current_row_ = 0;
    bool write_done_ = false;
    int write_clock_ = 0;
    bool write_completed_ = false;
    bool compute_done_ = false;
    int compute_clock_ = 0;
};

// Input validation is part of the library API, not just the command-line runner.
std::vector<Event> load_events(const std::string& path);

class Espresso {
public:
    explicit Espresso(const std::string& config_path);
    std::uint64_t process_frame(const std::string& event_path);
    std::uint64_t process_events(const std::vector<Event>& events);

private:
    // C++ preserves the original lexicographic ordering of network keys.
    std::vector<LayerConfig> layers_;
};

#endif  // ESPRESSO_COMPONENT_H
