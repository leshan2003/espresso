// Synthetic timing regressions and library input contracts; no external datasets.
#include "component.h"
#include "json.hpp"

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>

namespace fs = std::filesystem;

void require(bool condition, const std::string& context) {
    if (!condition) throw std::runtime_error(context);
}

template <typename Function>
void expect_error(Function function) {
    bool caught = false;
    try { function(); } catch (const std::exception&) { caught = true; }
    require(caught, "Invalid input was accepted");
}

struct Scratch {
    fs::path path = fs::temp_directory_path() /
        ("espresso-model-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Scratch() { require(fs::create_directory(path), "Cannot create test scratch directory"); }
    ~Scratch() { std::error_code error; fs::remove_all(path, error); }
    std::string write(const std::string& name, const std::string& text) const {
        const auto file = path / name;
        std::ofstream stream(file);
        stream << text;
        require(bool(stream), "Cannot write test fixture");
        return file.string();
    }
};

int main(int argc, char** argv) {
    try {
        require(argc == 2, "Expected repository root");
        const fs::path root(argv[1]);
        const auto config_path = root / "Costmodel/cpp/config/EspressoHarris_config.json";
        Espresso model(config_path.string());
        std::ifstream baseline_file(root / "Costmodel/tests/baselines.json");
        const auto baseline = nlohmann::json::parse(baseline_file);
        for (const auto& test : baseline.at("cases")) {
            std::vector<Event> events;
            for (const auto& event : test.at("events")) {
                events.push_back({{event[0].get<int>(), event[1].get<int>()}, event[2].get<int>()});
            }
            for (int repeat = 0; repeat < 2; ++repeat) {
                require(model.process_events(events) == test.at("cpp_cycles").get<std::uint64_t>(),
                        "Cycle regression: " + test.at("name").get<std::string>());
            }
        }
        for (const auto& events : std::vector<std::vector<Event>>{
                 {}, {{{-1, 0}, 1}}, {{{300, 0}, 1}}, {{{0, 256}, 1}}, {{{2, 0}, 1}, {{1, 0}, 1}}}) {
            expect_error([&] { model.process_events(events); });
        }
        Scratch scratch;
        const auto single = scratch.write("single.txt", "# synthetic\n\n+2 3 -1 # inline\n");
        const auto events = load_events(single);
        require(events.size() == 1 && events[0].value == -1, "Single event / comment parser");
        require(model.process_frame(single) > 0, "Single-event simulation");
        require(load_events(scratch.write("duplicates.txt", "2 3 -1\n2 3 +2\n")).size() == 2,
                "Duplicate coordinates must be allowed");
        for (const std::string text : {"", "# empty\n", "0 0 1.5", "0+0 1", "0 0 1 4", "0 0 1e2",
                                      "0 0 2147483648", "0 256 1", "300 0 1", "-1 0 1", "2 0 1\n1 0 1"}) {
            expect_error([&] { load_events(scratch.write("bad.txt", text)); });
        }
        expect_error([&] { load_events((scratch.path / "missing.txt").string()); });
        expect_error([&] { Espresso missing((scratch.path / "missing.json").string()); });
        for (const std::string text : {"[]", "{}", "{} trailing", "{\"network\":{},\"network\":{}}",
                                      "{\"network\":{\"layer\":{}}}"}) {
            expect_error([&] { Espresso invalid(scratch.write("bad.json", text)); });
        }
        std::ifstream config_file(config_path);
        const auto valid = nlohmann::json::parse(config_file);
        expect_error([&] { Espresso invalid(scratch.write("bad.json", valid.dump() + " trailing")); });
        expect_error([&] {
            Espresso invalid(scratch.write("bad.json",
                R"({"network":{"layer":{"kernelsize":3,"kernelsize":5,"datawidth":8,"computelatency":1}}})"));
        });
        for (const auto& parameter : std::vector<std::pair<std::string, int>>{
                 {"kernelsize", 2}, {"kernelsize", 999}, {"datawidth", 0}, {"computelatency", -1}}) {
            auto invalid = valid;
            invalid["network"].begin().value()[parameter.first] = parameter.second;
            expect_error([&] { Espresso rejected(scratch.write("bad.json", invalid.dump())); });
        }
        EventScheduler stage({"test", 3, 8, 1});
        stage.step(Event{{2, 2}, 1});
        for (int clock = 0; clock < 100 && stage.state() != SchedulerState::Update; ++clock) stage.step({}, true);
        require(stage.state() == SchedulerState::Update, "First event did not complete");
        stage.step(Event{{8, 8}, 7});
        for (int clock = 0; clock < 100 && stage.state() != SchedulerState::Read; ++clock) stage.step();
        require(stage.state() == SchedulerState::Read, "No pending output");
        for (int clock = 0; clock < 10; ++clock) require(!stage.step(), "Output escaped without ready");
        const auto output = stage.step({}, true);
        require(output.has_value() && output->value == 7, "Missing held output on ready");
        require(stage.state() == SchedulerState::Compare, "Ready did not advance the state");
        std::cout << "C++ timing regressions, repeated frames, input validation, and backpressure passed.\n";
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
