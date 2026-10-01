/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <linux/gpio.h>

#define TLMM_CHIP_LABEL "500000.pinctrl"
#define PIN_BOOT0        37
#define PIN_NRST         38
#define PIN_MCU_SPI_RDY  70

static int verbose = 0;

static int find_tlmm_gpiochip(char *out_path, size_t out_path_size) {
    char dev_path[64];
    int max_lines = 0;
    char fallback_path[64] = "";

    for (int i = 0; i < 16; i++) {
        snprintf(dev_path, sizeof(dev_path), "/dev/gpiochip%d", i);
        int fd = open(dev_path, O_RDWR | O_CLOEXEC);
        if (fd < 0) {
            continue;
        }

        struct gpiochip_info cinfo;
        memset(&cinfo, 0, sizeof(cinfo));
        if (ioctl(fd, GPIO_GET_CHIPINFO_IOCTL, &cinfo) == 0) {
            if (verbose) {
                fprintf(stderr, "Found %s: name='%s' label='%s' lines=%u\n",
                        dev_path, cinfo.name, cinfo.label, cinfo.lines);
            }
            if (strstr(cinfo.label, TLMM_CHIP_LABEL) != NULL) {
                strncpy(out_path, dev_path, out_path_size - 1);
                out_path[out_path_size - 1] = '\0';
                close(fd);
                return 0;
            }
            if (cinfo.lines > (unsigned int)max_lines) {
                max_lines = cinfo.lines;
                strncpy(fallback_path, dev_path, sizeof(fallback_path) - 1);
            }
        }
        close(fd);
    }

    if (max_lines >= 100 && fallback_path[0] != '\0') {
        if (verbose) {
            fprintf(stderr, "Exact label '%s' not found, falling back to %s (lines=%d)\n",
                    TLMM_CHIP_LABEL, fallback_path, max_lines);
        }
        strncpy(out_path, fallback_path, out_path_size - 1);
        out_path[out_path_size - 1] = '\0';
        return 0;
    }

    return -1;
}

static int gpio_set_line(int chip_fd, int line_num, int val) {
    // Try GPIO v2 first
    struct gpio_v2_line_request req2;
    memset(&req2, 0, sizeof(req2));
    req2.offsets[0] = (uint32_t)line_num;
    req2.num_lines = 1;
    strncpy(req2.consumer, "imola-gpio", sizeof(req2.consumer) - 1);
    req2.config.flags = GPIO_V2_LINE_FLAG_OUTPUT;
    req2.config.num_attrs = 1;
    req2.config.attrs[0].attr.id = GPIO_V2_LINE_ATTR_ID_OUTPUT_VALUES;
    req2.config.attrs[0].attr.values = val ? 1 : 0;
    req2.config.attrs[0].mask = 1;

    if (ioctl(chip_fd, GPIO_V2_GET_LINE_IOCTL, &req2) == 0) {
        if (verbose) {
            fprintf(stderr, "Set GPIO %d = %d (v2)\n", line_num, val);
        }
        close(req2.fd);
        return 0;
    }

    // Fallback to GPIO v1
    struct gpiohandle_request req1;
    memset(&req1, 0, sizeof(req1));
    req1.lineoffsets[0] = (uint32_t)line_num;
    req1.flags = GPIOHANDLE_REQUEST_OUTPUT;
    req1.default_values[0] = val ? 1 : 0;
    req1.lines = 1;
    strncpy(req1.consumer_label, "imola-gpio", sizeof(req1.consumer_label) - 1);

    if (ioctl(chip_fd, GPIO_GET_LINEHANDLE_IOCTL, &req1) == 0) {
        if (verbose) {
            fprintf(stderr, "Set GPIO %d = %d (v1)\n", line_num, val);
        }
        close(req1.fd);
        return 0;
    }

    fprintf(stderr, "imola-gpio: failed to set GPIO %d to %d: %s\n", line_num, val, strerror(errno));
    return -1;
}

static int gpio_get_line(int chip_fd, int line_num) {
    // Try GPIO v2 first
    struct gpio_v2_line_request req2;
    memset(&req2, 0, sizeof(req2));
    req2.offsets[0] = (uint32_t)line_num;
    req2.num_lines = 1;
    strncpy(req2.consumer, "imola-gpio", sizeof(req2.consumer) - 1);
    req2.config.flags = GPIO_V2_LINE_FLAG_INPUT;

    if (ioctl(chip_fd, GPIO_V2_GET_LINE_IOCTL, &req2) == 0) {
        struct gpio_v2_line_values vals;
        memset(&vals, 0, sizeof(vals));
        vals.mask = 1;
        int res = -1;
        if (ioctl(req2.fd, GPIO_V2_LINE_GET_VALUES_IOCTL, &vals) == 0) {
            res = (vals.bits & 1) ? 1 : 0;
        }
        close(req2.fd);
        if (res >= 0) return res;
    }

    // Fallback to GPIO v1
    struct gpiohandle_request req1;
    memset(&req1, 0, sizeof(req1));
    req1.lineoffsets[0] = (uint32_t)line_num;
    req1.flags = GPIOHANDLE_REQUEST_INPUT;
    req1.lines = 1;
    strncpy(req1.consumer_label, "imola-gpio", sizeof(req1.consumer_label) - 1);

    if (ioctl(chip_fd, GPIO_GET_LINEHANDLE_IOCTL, &req1) == 0) {
        struct gpiohandle_data data;
        memset(&data, 0, sizeof(data));
        int res = -1;
        if (ioctl(req1.fd, GPIOHANDLE_GET_LINE_VALUES_IOCTL, &data) == 0) {
            res = data.values[0] ? 1 : 0;
        }
        close(req1.fd);
        return res;
    }

    fprintf(stderr, "imola-gpio: failed to get GPIO %d: %s\n", line_num, strerror(errno));
    return -1;
}

static void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s [options] <command> [args]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -c <chip_path>    Explicit gpiochip path (default: auto-detect 500000.pinctrl)\n");
    fprintf(stderr, "  -v                Verbose output\n");
    fprintf(stderr, "Commands:\n");
    fprintf(stderr, "  set <pin> <0|1>   Set GPIO pin to 0 or 1\n");
    fprintf(stderr, "  get <pin>         Get GPIO pin value (outputs 0 or 1)\n");
    fprintf(stderr, "  ready             Set BOOT0=0, release NRST, and assert MCU_SPI_RDY(70)=1 for arduino-router\n");
    fprintf(stderr, "  reset             Pulse NRST(38) and clear RDY(70) to restart MCU firmware\n");
    fprintf(stderr, "  init              Set BOOT0(37)=0 to ready STM32 for normal execution\n");
}

int main(int argc, char **argv) {
    char chip_path[64] = "";
    int opt;

    // Detect invocation via symlink (e.g. imola-ready, imola-reset)
    const char *prog_name = strrchr(argv[0], '/');
    prog_name = prog_name ? prog_name + 1 : argv[0];

    const char *cmd = NULL;
    if (strstr(prog_name, "ready") != NULL) {
        cmd = "ready";
    } else if (strstr(prog_name, "reset") != NULL) {
        cmd = "reset";
    } else if (strstr(prog_name, "init") != NULL) {
        cmd = "init";
    }

    while ((opt = getopt(argc, argv, "c:v")) != -1) {
        switch (opt) {
            case 'c':
                strncpy(chip_path, optarg, sizeof(chip_path) - 1);
                chip_path[sizeof(chip_path) - 1] = '\0';
                break;
            case 'v':
                verbose = 1;
                break;
            default:
                print_usage(argv[0]);
                return 1;
        }
    }

    if (optind < argc) {
        cmd = argv[optind];
    } else if (cmd == NULL) {
        print_usage(argv[0]);
        return 1;
    }

    if (chip_path[0] == '\0') {
        if (find_tlmm_gpiochip(chip_path, sizeof(chip_path)) < 0) {
            fprintf(stderr, "imola-gpio: could not locate TLMM gpiochip (%s)\n", TLMM_CHIP_LABEL);
            return 1;
        }
    }

    if (verbose) {
        fprintf(stderr, "Using gpiochip: %s, command: %s\n", chip_path, cmd);
    }

    int chip_fd = open(chip_path, O_RDWR | O_CLOEXEC);
    if (chip_fd < 0) {
        fprintf(stderr, "imola-gpio: failed to open %s: %s\n", chip_path, strerror(errno));
        return 1;
    }

    int ret = 0;
    if (strcmp(cmd, "set") == 0) {
        if (optind + 2 >= argc) {
            fprintf(stderr, "imola-gpio: 'set' requires <pin> and <value>\n");
            ret = 1;
        } else {
            int pin = atoi(argv[optind + 1]);
            int val = atoi(argv[optind + 2]) ? 1 : 0;
            ret = gpio_set_line(chip_fd, pin, val);
        }
    } else if (strcmp(cmd, "get") == 0) {
        if (optind + 1 >= argc) {
            fprintf(stderr, "imola-gpio: 'get' requires <pin>\n");
            ret = 1;
        } else {
            int pin = atoi(argv[optind + 1]);
            int val = gpio_get_line(chip_fd, pin);
            if (val >= 0) {
                printf("%d\n", val);
                ret = 0;
            } else {
                ret = 1;
            }
        }
    } else if (strcmp(cmd, "ready") == 0) {
        // Ensure BOOT0=0 (user flash execution), NRST=1 (released from reset), and RDY=1
        if (gpio_set_line(chip_fd, PIN_BOOT0, 0) < 0) ret = 1;
        if (gpio_set_line(chip_fd, PIN_NRST, 1) < 0) ret = 1;
        usleep(10000); // 10ms settle
        if (gpio_set_line(chip_fd, PIN_MCU_SPI_RDY, 1) < 0) ret = 1;
        if (verbose) {
            fprintf(stderr, "imola-gpio: asserted MCU_SPI_RDY=1, BOOT0=0, NRST=1\n");
        }
    } else if (strcmp(cmd, "init") == 0) {
        // BOOT0=0
        ret = gpio_set_line(chip_fd, PIN_BOOT0, 0);
    } else if (strcmp(cmd, "reset") == 0) {
        // Stop RDY, pull reset low, then release high with BOOT0=0
        gpio_set_line(chip_fd, PIN_MCU_SPI_RDY, 0);
        gpio_set_line(chip_fd, PIN_BOOT0, 0);
        gpio_set_line(chip_fd, PIN_NRST, 0);
        usleep(50000); // 50ms reset pulse
        ret = gpio_set_line(chip_fd, PIN_NRST, 1);
        usleep(20000); // 20ms settle
        if (verbose) {
            fprintf(stderr, "imola-gpio: completed reset sequence\n");
        }
    } else {
        fprintf(stderr, "imola-gpio: unknown command '%s'\n", cmd);
        print_usage(argv[0]);
        ret = 1;
    }

    close(chip_fd);
    return ret;
}
