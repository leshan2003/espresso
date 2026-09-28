#ifndef COMPONENT_H
#define COMPONENT_H

#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <cmath>
#include <map>
#include <utility>

const int IMGWIDTH = 256;
const int IMGHEIGHT = 300;

class Event {
public:
    std::pair<int, int> addr2d;
    int value;

    Event(std::pair<int, int> addr = {0,0}, int val = 0) : addr2d(addr), value(val) {}
};

class Eventscheduler {
private:

public:
    int halfkernelsize;
    std::vector<std::vector<std::pair<int, int>>> NPendingFIFOs;
    Event currentevent;
    Event lastevent;
    int outputwindowabsaddr;
    int curRow;
    int writedone;
    int writeclk;
    int writecompleted;
    int computeclk;

    int getabsaddr(std::pair<int, int> addr2d);
    std::pair<int, int> get2daddr(int addrabs);
    int kernel_size;
    int data_width;
    std::string kernel_name;
    int state;  // 0: update, 1: compare, 2: read, 3: write
    int computelatency;
    int computedone;
    Event outputevent;
    Eventscheduler(std::string name, int size, int width, int computelatency);
    void step_one_clock(Event inputevent = Event(), int inputeventvalid = 0, int readyforevent = 0);
    void update_NPendingFIFOs();
    void update_NPendingFIFOs_remove();
    int getMinAddrInNPendingFIFOs();
};

class Espresso {
private:
    void load_config(std::string config_file);

public:
    std::map<std::string, std::map<std::string, int>> network;
    int layernum;
    std::vector<Eventscheduler> architecture;
    Espresso(std::string config_file);
    int process_frame(std::string eventtxtfile);
};

#endif // COMPONENT_H
