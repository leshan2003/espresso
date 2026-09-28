#include "component.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>
#include <json.hpp>

using json = nlohmann::json;

// Event class doesn't need additional implementation as it's all in the header

// Eventscheduler implementation
Eventscheduler::Eventscheduler(std::string name, int size, int width, int computelatency)
    : kernel_name(name), kernel_size(size), data_width(width), computelatency(computelatency) {
    halfkernelsize = kernel_size / 2;
    state = 0;
    NPendingFIFOs = std::vector<std::vector<std::pair<int, int>>>(kernel_size);
    currentevent = Event();
    lastevent = Event();
    outputwindowabsaddr = 0;
    curRow = 0;
    writedone = 0;
    writeclk = 0;
    writecompleted = 0;
    computedone = 0;
    computeclk = 0;
    outputevent = Event();
}

int Eventscheduler::getabsaddr(std::pair<int, int> addr2d) {
    return addr2d.first * IMGWIDTH + addr2d.second;
}

std::pair<int, int> Eventscheduler::get2daddr(int addrabs) {
    return {addrabs / IMGWIDTH, addrabs % IMGWIDTH};
}

void Eventscheduler::step_one_clock(Event inputevent, int inputeventvalid, int readyforevent) {
    if (state == 0) {
        if (inputeventvalid == 1) {
            lastevent = currentevent;
            currentevent = inputevent;
            update_NPendingFIFOs();
            state = 1;
        } else {
            state = 0;
        }
    } else if (state == 1) {
        outputwindowabsaddr = getMinAddrInNPendingFIFOs();
        if (outputwindowabsaddr < (getabsaddr(currentevent.addr2d) - IMGWIDTH * halfkernelsize - halfkernelsize)) {
            update_NPendingFIFOs_remove();
            state = 2;
            computedone = 0;
        } else {
            state = 3;
            writedone = 0;
            writeclk = 0;
            writecompleted = 0;
        }
    } else if (state == 2) {
        if (computedone == 1) {
            if (readyforevent) {
                state = 1;
                computedone = 0;
                outputevent = Event(
                    get2daddr(outputwindowabsaddr),
                    currentevent.value
                );
            } else {
                state = 2;
            }
        } else {
            state = 2;
            if (computeclk < computelatency) {
                computeclk++;
            } else {
                computeclk = 0;
                computedone = 1;
            }
        }
    } else if (state == 3) {
        if (writecompleted) {
            state = 0;
            writecompleted = 0;
            writedone = 0;
        } else {
            if (writedone == 1) {
                if (writeclk < 1) {
                    writeclk++;
                } else {
                    writeclk = 0;
                    writecompleted = 1;
                }
            } else {
                if (curRow < currentevent.addr2d.first - kernel_size + 1) {
                    curRow++;
                } else {
                    writedone = 1;
                }
            }
        }
    }
}

void Eventscheduler::update_NPendingFIFOs() {
    if (currentevent.addr2d.first != lastevent.addr2d.first ||
        currentevent.addr2d.second >= (lastevent.addr2d.second + kernel_size)) {
        for (int j = -halfkernelsize; j <= halfkernelsize; j++) {
            for (int i = -halfkernelsize; i <= halfkernelsize; i++) {
                NPendingFIFOs[i+halfkernelsize].emplace_back(
                    currentevent.addr2d.first + i,
                    currentevent.addr2d.second + j
                );
            }
        }
    } else {
        int difference = currentevent.addr2d.second - lastevent.addr2d.second;
        for (int j = halfkernelsize+1-difference; j <= halfkernelsize; j++) {
            for (int i = -halfkernelsize; i <= halfkernelsize; i++) {
                NPendingFIFOs[i+halfkernelsize].emplace_back(
                    currentevent.addr2d.first + i,
                    currentevent.addr2d.second + j
                );
            }
        }
    }
}

void Eventscheduler::update_NPendingFIFOs_remove() {
    for (int i = 0; i < kernel_size; i++) {
        if (!NPendingFIFOs[i].empty()) {
            if (getabsaddr(NPendingFIFOs[i][0]) == outputwindowabsaddr) {
                NPendingFIFOs[i].erase(NPendingFIFOs[i].begin());
            }
        }
    }
}

int Eventscheduler::getMinAddrInNPendingFIFOs() {
    int min_abs_addr = IMGWIDTH * IMGHEIGHT;
    for (int i = 0; i < kernel_size; i++) {
        if (!NPendingFIFOs[i].empty()) {
            if (getabsaddr(NPendingFIFOs[i][0]) < min_abs_addr) {
                min_abs_addr = getabsaddr(NPendingFIFOs[i][0]);
            }
        }
    }
    return min_abs_addr;
}

// Espresso implementation
Espresso::Espresso(std::string config_file) {
    load_config(config_file);
}

void Espresso::load_config(std::string config_file) {
    std::ifstream file(config_file);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open config file " << config_file << std::endl;
        return;
    }

    json j;
    file >> j;
    network = j["network"].get<std::map<std::string, std::map<std::string, int>>>();
    layernum = network.size();
    for (const auto& [layer_name, layer_params] : network) {
        architecture.emplace_back(
            Eventscheduler(
                layer_name,
                layer_params.at("kernelsize"),
                layer_params.at("datawidth"),
                layer_params.at("computelatency")
            )
        );
    }

    // architecture.emplace_back(
    //     Eventscheduler("sobel", 3, 4, 1)
    // );
    // architecture.emplace_back(
    //     Eventscheduler("guassian_harris", 5, 8, 3)
    // );
    // architecture.emplace_back(
    //     Eventscheduler("nms", 5, 16, 2)
    // );
}

int Espresso::process_frame(std::string eventtxtfile) {
    std::vector<std::vector<int>> waveform(layernum);
    int clocknum = 0;

    std::vector<std::vector<int>> eventdata;
    std::ifstream file(eventtxtfile);
    if (!file.is_open()) {
        std::cerr << "Error: File '" << eventtxtfile << "' not found." << std::endl;
        return 0;
    }

    std::string line;
    while (std::getline(file, line)) {
        std::istringstream iss(line);
        std::vector<int> row;
        int value;
        while (iss >> value) {
            row.push_back(value);
        }
        eventdata.push_back(row);
    }

    int eventindex = 0;
    while (true) {
        int flag = 0;
        for (auto& es : architecture) {
            if (es.state != 0) {
                flag = 1;
            }
        }
        if (flag == 0 && eventindex >= eventdata.size()) {
            break;
        }

        clocknum++;
        int eventavailable = 0;

        for (int i = 0; i < architecture.size(); i++) {
            waveform[i].push_back(architecture[i].state);

            if (architecture[i].state == 2) {
                if (architecture[i].computedone == 1) {
                    if (i == architecture.size() - 1) {
                        architecture[i].step_one_clock(Event(), 0, 1);
                    } else if (architecture[i+1].state == 0) {
                        architecture[i].step_one_clock(Event(), 0, 1);
                        eventavailable = 1;
                    } else {
                        architecture[i].step_one_clock(Event(), 0, 0);
                    }
                } else {
                    architecture[i].step_one_clock(Event(), 0, 0);
                }
            } else if (architecture[i].state == 0) {
                if (i == 0) {
                    if (eventindex < eventdata.size()) {
                        Event newevent(
                            {eventdata[eventindex][0], eventdata[eventindex][1]},
                            eventdata[eventindex][2]
                        );
                        architecture[i].step_one_clock(newevent, 1, 0);
                        eventindex++;
                    } else {
                        architecture[i].step_one_clock(Event(), 0, 0);
                    }
                } else if (eventavailable == 1) {
                    architecture[i].step_one_clock(architecture[i-1].outputevent, 1, 0);
                    eventavailable = 0;
                } else {
                    architecture[i].step_one_clock(Event(), 0, 0);
                }
            } else {
                architecture[i].step_one_clock();
            }
        }
    }


    return clocknum;
}
