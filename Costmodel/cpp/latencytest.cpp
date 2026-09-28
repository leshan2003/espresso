#include "component.h"

#include <cmath>
#include <iostream>
#include <stdexcept>
#include <string>

int main(int argc, char* argv[]) {
    if (argc == 2 && std::string(argv[1]) == "--help") {
        std::cout << "Usage: latencytest CONFIG.json EVENTS.txt [CLOCK_MHZ]\n";
        return 0;
    }
    if (argc != 3 && argc != 4) {
        std::cerr << "Usage: latencytest CONFIG.json EVENTS.txt [CLOCK_MHZ]\n";
        return 2;
    }
    try {
        double clock_mhz = 100.0;
        if (argc == 4) {
            const std::string value(argv[3]);
            std::size_t consumed = 0;
            clock_mhz = std::stod(value, &consumed);
            if (consumed != value.size()) {
                throw std::invalid_argument("Clock must be a number without trailing characters");
            }
        }
        if (!std::isfinite(clock_mhz) || clock_mhz <= 0) {
            throw std::invalid_argument("Clock must be finite and positive");
        }
        Espresso model(argv[1]);
        const auto cycles = model.process_frame(argv[2]);
        std::cout << "Total clock cycles: " << cycles << '\n'
                  << "Latency: " << cycles / clock_mhz << " us\n"
                  << "Throughput: " << clock_mhz * 1e6 / cycles << " fps\n";
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return 1;
    }
    return 0;
}
