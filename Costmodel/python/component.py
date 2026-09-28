import numpy as np
import json


class Event:
    def __init__(self, addr2d, value):
        self.addr2d = addr2d  # 2D address (row, col)
        self.value = value

class Eventscheduler:
    def __init__(self, kernel_name, kernel_size, data_width, img_width, img_height):
        self.kernel_size = kernel_size
        self.halfkernelsize = kernel_size // 2
        self.data_width = data_width
        self.img_width = img_width
        self.img_height = img_height
        self.kernel_name = kernel_name
        self.state = 0      # 0: update, 1: compare, 2: read, 3: write
        if 'pool' in self.kernel_name or 'sparse' in self.kernel_name:
            self.NPendingFIFOs = []
        else:
            self.NPendingFIFOs = [[] for _ in range(kernel_size)]
        # self.ShiftHashTable = [[(0,0)]*IMGWIDTH for _ in range(kernel_size)]
        self.currentevent = Event(addr2d=(0,0), value=0)
        self.lastevent = Event(addr2d=(0,0), value=0)
        self.outputwindowabsaddr = 0
        self.curRow = 0
        self.writedone = 0
        self.writeclk = 0
        self.writecompleted = 0
        self.computedone = 0
        self.computeclk = 0
        if self.kernel_name == 'sobel':
            self.computelatency = 1
        elif self.kernel_name == 'gaussian_harris':
            self.computelatency = 3
        elif self.kernel_name == 'nms':
            self.computelatency = 2
        else:
            self.computelatency = 1

    def step_one_clock(self, inputevent: Event = Event(addr2d=(0,0), value=0), inputeventvalid = 0, readyforevent = 0):
        # print(f"{self.kernel_name} state: {self.state}")
        if self.state == 0:
            if inputeventvalid == 1:
                self.lastevent = self.currentevent
                self.currentevent = inputevent
                self.update_NPendingFIFOs()
                self.state = 1
            else:
                self.state = 0
        elif self.state == 1:
            self.outputwindowabsaddr = self.getMinAddrInNPendingFIFOs()
            # if  self.outputwindowabsaddr < (self.getabsaddr(self.currentevent.addr2d) - IMGWIDTH * self.halfkernelsize - self.halfkernelsize):
            if  self.outputwindowabsaddr < (self.getabsaddr(self.currentevent.addr2d)):
                self.update_NPendingFIFOs_remove()
                self.state = 2
                self.computedone = 0
            else:
                self.state = 3
                self.writedone = 0
                self.writeclk = 0
                self.writecompleted = 0
        elif self.state == 2:
            if (self.computedone == 1):
                if (readyforevent):
                    self.state = 1
                    self.computedone = 0
                    return Event(addr2d=self.get2daddr(self.outputwindowabsaddr), value=1)
                else:
                    self.state = 2
            else:
                self.state = 2
                if (self.computeclk < self.computelatency):
                    self.computeclk += 1
                else:
                    self.computeclk = 0
                    self.computedone = 1
        elif self.state == 3:
            if (self.writecompleted):
                self.state = 0
                self.writecompleted = 0
                self.writedone = 0
            else:
                if (self.writedone == 1):
                    if (self.writeclk < 1):
                        self.writeclk += 1
                    else:
                        self.writeclk = 0
                        self.writecompleted = 1
                else:
                    if (self.curRow < self.currentevent.addr2d[0] - self.kernel_size + 1):
                        self.curRow += 1
                    else:
                        self.writedone = 1

    def update_NPendingFIFOs(self):
        # Logic to update NPendingFIFOs
        if "pool" in self.kernel_name:
            output_addr_x = self.currentevent.addr2d[0] if (self.currentevent.addr2d[0] % 2 == 1) else self.currentevent.addr2d[0] + 1
            output_addr_y = self.currentevent.addr2d[1] if (self.currentevent.addr2d[1] % 2 == 1) else self.currentevent.addr2d[1] + 1
            if self.NPendingFIFOs == []:
                self.NPendingFIFOs.append((output_addr_x, output_addr_y))
            elif self.NPendingFIFOs[-1] != (output_addr_x, output_addr_y):
                self.NPendingFIFOs.append((output_addr_x, output_addr_y))
        elif "sparse" in self.kernel_name:
            self.NPendingFIFOs.append((self.currentevent.addr2d[0]+self.halfkernelsize, self.currentevent.addr2d[1]+self.halfkernelsize))
        else:
            if (self.currentevent.addr2d[0] != self.lastevent.addr2d[0] or self.currentevent.addr2d[1] >= (self.lastevent.addr2d[1] + self.kernel_size)):
                # for j in range(-self.halfkernelsize, self.halfkernelsize+1, 1):
                for j in range(0, 2*self.halfkernelsize+1, 1):
                #     for i in range(-self.halfkernelsize, self.halfkernelsize+1, 1):
                    for i in range(0, 2*self.halfkernelsize+1, 1):
                        self.NPendingFIFOs[i].append((self.currentevent.addr2d[0]+i, self.currentevent.addr2d[1]+j))
            else:
                difference = self.currentevent.addr2d[1] - self.lastevent.addr2d[1]
                # for j in range(self.halfkernelsize+1-difference, self.halfkernelsize+1, 1):
                for j in range(2*self.halfkernelsize+1-difference, 2*self.halfkernelsize+1, 1):
                    # for i in range(-self.halfkernelsize, self.halfkernelsize+1, 1):
                    for i in range(0, 2*self.halfkernelsize+1, 1):
                        self.NPendingFIFOs[i].append((self.currentevent.addr2d[0]+i, self.currentevent.addr2d[1]+j))

    def update_NPendingFIFOs_remove(self):
        if "pool" in self.kernel_name or "sparse" in self.kernel_name:
            if (self.NPendingFIFOs != []):
                if (self.getabsaddr(self.NPendingFIFOs[0]) == self.outputwindowabsaddr):
                    self.NPendingFIFOs.pop(0)
        else:
            for i in range(self.kernel_size):
                if (self.NPendingFIFOs[i] != []):
                    if (self.getabsaddr(self.NPendingFIFOs[i][0]) == self.outputwindowabsaddr):
                        self.NPendingFIFOs[i].pop(0)

    def getMinAddrInNPendingFIFOs(self):
        min_abs_addr = 2160*3840
        if "pool" in self.kernel_name or "sparse" in self.kernel_name:
            if (self.NPendingFIFOs != []):
                if (self.getabsaddr(self.NPendingFIFOs[0]) < min_abs_addr):
                    min_abs_addr = self.getabsaddr(self.NPendingFIFOs[0])
        else:
            for i in range(self.kernel_size):
                if (self.NPendingFIFOs[i] != []):
                    if (self.getabsaddr(self.NPendingFIFOs[i][0]) < min_abs_addr):
                        # min_2d_addr = self.NPendingFIFOs[i][0]
                        min_abs_addr = self.getabsaddr(self.NPendingFIFOs[i][0])
        return min_abs_addr

    def getabsaddr(self, addr2d):
        return addr2d[0] * self.img_width + addr2d[1]

    def get2daddr(self, addrabs):
        return (addrabs // self.img_width, addrabs % self.img_width)

class Espresso:
    def __init__(self, config_file):
        self.network = {}
        self.layernum = 0
        self.img_width = 0
        self.img_height = 0
        self.architecture = []
        self.load_config(config_file)

    def load_config(self, config_file):
        with open(config_file, 'r') as file:
            config = json.load(file)
        self.network = config['network']
        self.imginfo = config['imginfo']
        self.img_width = self.imginfo['img_width']
        self.img_height = self.imginfo['img_height']
        self.layernum = len(self.network)
        for layer_name, layer_params in self.network.items():
            self.architecture.append(
                Eventscheduler(
                    layer_name,
                    layer_params['kernelsize'],
                    layer_params['datawidth'],
                    img_width=self.img_width,
                    img_height=self.img_height
                )
            )

        # print architecture
        # for i in range(self.layernum):
        #     print(f"Layer {i}: {self.architecture[i].kernel_name}, kernel size: {self.architecture[i].kernel_size}, data width: {self.architecture[i].data_width}, compute latency: {self.architecture[i].computelatency}")

    def process_frame(self, eventtxtfile):
        waveform = [[] for _ in range(self.layernum)]
        clocknum = 0
        try:
            eventdata = np.loadtxt(eventtxtfile, dtype=int)
        except FileNotFoundError:
            print(f"Error: File '{eventtxtfile}' not found.")
            return

        eventindex = 0
        while True:
            flag = 0
            for es in self.architecture:
                if es.state != 0:
                    flag = 1
            if flag == 0 and eventindex >= len(eventdata):
                break

            clocknum += 1
            tempevent = Event(addr2d=(0,0), value=0)
            eventavailable = 0
            for i in range(len(self.architecture)):
                waveform[i].append(self.architecture[i].state)
                if self.architecture[i].state == 2:
                    if self.architecture[i].computedone == 1:
                        if i == len(self.architecture) - 1:
                            self.architecture[i].step_one_clock(readyforevent=1)
                        elif self.architecture[i+1].state == 0:
                            tempevent = self.architecture[i].step_one_clock(readyforevent=1)
                            eventavailable = 1
                        else:
                            self.architecture[i].step_one_clock(readyforevent=0)
                    else:
                        self.architecture[i].step_one_clock(readyforevent=0)
                elif self.architecture[i].state == 0:
                    if i == 0:
                        if eventindex < len(eventdata):
                            newevent = Event(addr2d=(eventdata[eventindex][0], eventdata[eventindex][1]), value=eventdata[eventindex][2])
                            self.architecture[i].step_one_clock(inputevent=newevent, inputeventvalid=1)
                            eventindex += 1
                        else:
                            self.architecture[i].step_one_clock(inputeventvalid=0)
                    elif eventavailable == 1:
                        self.architecture[i].step_one_clock(inputevent=tempevent, inputeventvalid=1)
                        eventavailable = 0
                    else:
                        self.architecture[i].step_one_clock(inputeventvalid=0)
                else:
                    self.architecture[i].step_one_clock()

        # np.savetxt(f'results/waveform.txt', waveform, fmt='%d')
        return clocknum


if __name__ == "__main__":
    raise SystemExit("Run run.py with an event file; see README.md.")
