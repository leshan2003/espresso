#include "component.h"
#include <cmath>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include "json.hpp"

int main(int argc, char* argv[]) {
    if (argc != 3 && argc != 4) {
        std::cerr << "Usage: latencytest CONFIG.json EVENTS.txt [CLOCK_MHZ]\n";
        return 2;
    }
    try {
        const double mhz = argc == 4 ? std::stod(argv[3]) : 100.0;
        if (!std::isfinite(mhz) || mhz <= 0) throw std::runtime_error("Clock must be finite and positive");
        std::ifstream config(argv[1]);
        if (!config) throw std::runtime_error("Cannot open configuration");
        nlohmann::json j;
        config >> j;
        if (!j.contains("network") || j.at("network").empty()) throw std::runtime_error("Configuration needs a network");
        std::ifstream events(argv[2]);
        if (!events) throw std::runtime_error("Cannot open event file");
        std::string line;
        int count = 0, previous = -1;
        while (std::getline(events, line)) {
            std::istringstream record(line);
            int row, col, value;
            std::string extra;
            if (!(record >> row >> col >> value) || (record >> extra)) throw std::runtime_error("Expected three integers per line");
            if (row < 0 || row >= IMGHEIGHT || col < 0 || col >= IMGWIDTH) throw std::runtime_error("Coordinates exceed C++ image dimensions");
            const int address = row * IMGWIDTH + col;
            if (address < previous) throw std::runtime_error("Events must use row-major order");
            previous = address;
            ++count;
        }
        if (count < 2) throw std::runtime_error("Expected at least two events");
        Espresso espresso(argv[1]);
        const int cycles = espresso.process_frame(argv[2]);
        if (cycles <= 0) throw std::runtime_error("The model produced no clock cycles");
        std::cout << "Total clock cycles: " << cycles << '\n'
                  << "Latency: " << cycles / mhz << " us\n"
                  << "Throughput: " << mhz * 1e6 / cycles << " fps\n";
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return 1;
    }
    return 0;
}
