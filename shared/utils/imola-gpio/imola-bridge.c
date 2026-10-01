#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#define ROUTER_SOCKET_PATH "/dev/socket/arduino-router.sock"
#define OPENOCD_HOST "127.0.0.1"
#define OPENOCD_PORT 4444

static int g_openocd_fd = -1;

static int connect_openocd() {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_port = htons(OPENOCD_PORT);
    sin.sin_addr.s_addr = inet_addr(OPENOCD_HOST);

    if (connect(fd, (struct sockaddr *)&sin, sizeof(sin)) < 0) {
        close(fd);
        return -1;
    }

    // Read initial banner
    char banner[1024];
    usleep(50000);
    recv(fd, banner, sizeof(banner), MSG_DONTWAIT);
    return fd;
}

static void send_openocd(const char *cmd) {
    if (g_openocd_fd < 0) {
        g_openocd_fd = connect_openocd();
        if (g_openocd_fd < 0) {
            fprintf(stderr, "imola-bridge: OpenOCD not connected, cannot execute: %s\n", cmd);
            return;
        }
    }

    char buf[256];
    int len = snprintf(buf, sizeof(buf), "%s\n", cmd);
    if (write(g_openocd_fd, buf, len) < 0) {
        close(g_openocd_fd);
        g_openocd_fd = connect_openocd();
        if (g_openocd_fd >= 0) {
            write(g_openocd_fd, buf, len);
        }
    }
    // Small delay to let OpenOCD process
    usleep(2000);
    char dummy[512];
    recv(g_openocd_fd, dummy, sizeof(dummy), MSG_DONTWAIT);
}

static void init_stm32_hw() {
    printf("imola-bridge: Initializing STM32 hardware registers via OpenOCD...\n");
    // Enable GPIO clocks for ports A, B, C, H
    send_openocd("mww 0x46020c8c 0x000001ff");
    // Configure GPIOB: PB13 (D13) as output
    send_openocd("mww 0x42020400 0x04000000");
    // Configure GPIOH: PH10..PH15 (RGB LEDs) as output
    send_openocd("mww 0x42021c00 0x55500000");
    // Turn all RGB LEDs OFF (pull high: 0x0000fc00)
    send_openocd("mww 0x42021c18 0x0000fc00");
    // Turn D13 LOW initially (0x20000000)
    send_openocd("mww 0x42020418 0x20000000");
    printf("imola-bridge: STM32 hardware registers initialized.\n");
    fflush(stdout);
}

static void execute_pin_action(const char *pin, int val) {
    char cmd[128];
    printf("imola-bridge: EXECUTE PIN ACTION: %s -> %d\n", pin, val);

    if (strcmp(pin, "D13") == 0) {
        // Physical header pin D13 is PB13
        if (val) {
            send_openocd("mww 0x42020418 0x00002000"); // PB13 HIGH (3.3V)
            send_openocd("mww 0x42021c18 0x10000000"); // Mirror to LED3_B (ON)
        } else {
            send_openocd("mww 0x42020418 0x20000000"); // PB13 LOW (0V)
            send_openocd("mww 0x42021c18 0x00001000"); // Mirror to LED3_B (OFF)
        }
    } else if (strcmp(pin, "LED3_R") == 0) {
        // PH10 (Active Low: 0 = ON, 1 = OFF)
        snprintf(cmd, sizeof(cmd), "mww 0x42021c18 0x%08x", (val == 0) ? 0x04000000 : 0x00000400);
        send_openocd(cmd);
    } else if (strcmp(pin, "LED3_G") == 0) {
        // PH11 (Active Low: 0 = ON, 1 = OFF)
        snprintf(cmd, sizeof(cmd), "mww 0x42021c18 0x%08x", (val == 0) ? 0x08000000 : 0x00000800);
        send_openocd(cmd);
    } else if (strcmp(pin, "LED3_B") == 0) {
        // PH12 (Active Low: 0 = ON, 1 = OFF)
        snprintf(cmd, sizeof(cmd), "mww 0x42021c18 0x%08x", (val == 0) ? 0x10000000 : 0x00001000);
        send_openocd(cmd);
    } else if (strcmp(pin, "LED4_R") == 0) {
        // PH13 (Active Low: 0 = ON, 1 = OFF)
        snprintf(cmd, sizeof(cmd), "mww 0x42021c18 0x%08x", (val == 0) ? 0x20000000 : 0x00002000);
        send_openocd(cmd);
    } else if (strcmp(pin, "LED4_G") == 0) {
        // PH14 (Active Low: 0 = ON, 1 = OFF)
        snprintf(cmd, sizeof(cmd), "mww 0x42021c18 0x%08x", (val == 0) ? 0x40000000 : 0x00004000);
        send_openocd(cmd);
    } else if (strcmp(pin, "LED4_B") == 0) {
        // PH15 (Active Low: 0 = ON, 1 = OFF)
        snprintf(cmd, sizeof(cmd), "mww 0x42021c18 0x%08x", (val == 0) ? 0x80000000 : 0x00008000);
        send_openocd(cmd);
    } else {
        printf("imola-bridge: Pin %s action acknowledged (header/virtual).\n", pin);
    }
}

/**
 * Robust MessagePack-RPC Request Parser:
 * Matches [type:0, msg_id, method_str, [pin_str, val_bool_or_int]]
 *
 * Returns:
 * > 0: Number of bytes consumed for the complete message
 *   0: Incomplete packet, need more data
 * < 0: Protocol sync error (caller should advance 1 byte)
 */
static int parse_rpc_request(const unsigned char *buf, size_t len,
                             uint32_t *out_msg_id,
                             char *out_method, size_t method_max,
                             char *out_pin, size_t pin_max,
                             int *out_val)
{
    if (len < 4) return 0; // Need at least header + type + msg_id prefix

    // Must be fixarray of 4 elements: [type, msg_id, method, params]
    if (buf[0] != 0x94) return -1;
    // Type must be REQUEST (0)
    if (buf[1] != 0x00) return -1;

    size_t pos = 2;

    // Decode msg_id (positive fixint or uint8/16/32)
    uint32_t msg_id = 0;
    if (buf[pos] <= 0x7f) {
        msg_id = buf[pos++];
    } else if (buf[pos] == 0xcc) {
        if (len < pos + 2) return 0;
        pos++;
        msg_id = buf[pos++];
    } else if (buf[pos] == 0xcd) {
        if (len < pos + 3) return 0;
        pos++;
        msg_id = ((uint32_t)buf[pos] << 8) | buf[pos + 1];
        pos += 2;
    } else if (buf[pos] == 0xce) {
        if (len < pos + 5) return 0;
        pos++;
        msg_id = ((uint32_t)buf[pos] << 24) | ((uint32_t)buf[pos + 1] << 16) |
                 ((uint32_t)buf[pos + 2] << 8) | buf[pos + 3];
        pos += 4;
    } else {
        return -1; // Unsupported msg_id format
    }
    *out_msg_id = msg_id;

    // Decode method string
    if (len < pos + 1) return 0;
    if ((buf[pos] & 0xe0) != 0xa0) return -1; // Must be fixstr
    size_t method_len = buf[pos] & 0x1f;
    pos++;

    if (len < pos + method_len) return 0;
    size_t copy_m = method_len < (method_max - 1) ? method_len : (method_max - 1);
    memcpy(out_method, &buf[pos], copy_m);
    out_method[copy_m] = '\0';
    pos += method_len;

    // Decode params array (fixarray: 0x90 | count)
    if (len < pos + 1) return 0;
    if ((buf[pos] & 0xf0) != 0x90) return -1;
    size_t param_count = buf[pos] & 0x0f;
    pos++;

    if (param_count >= 1) {
        // Param 0: Pin name string
        if (len < pos + 1) return 0;
        if ((buf[pos] & 0xe0) != 0xa0) return -1;
        size_t pin_len = buf[pos] & 0x1f;
        pos++;

        if (len < pos + pin_len) return 0;
        size_t copy_p = pin_len < (pin_max - 1) ? pin_len : (pin_max - 1);
        memcpy(out_pin, &buf[pos], copy_p);
        out_pin[copy_p] = '\0';
        pos += pin_len;
    } else {
        out_pin[0] = '\0';
    }

    if (param_count >= 2) {
        // Param 1: Value (bool 0xc2/0xc3, int 0x00/0x01, or uint8 0xcc)
        if (len < pos + 1) return 0;
        unsigned char v = buf[pos++];
        if (v == 0xc3 || v == 0x01) {
            *out_val = 1;
        } else if (v == 0xc2 || v == 0x00) {
            *out_val = 0;
        } else if (v == 0xcc) {
            if (len < pos + 1) return 0;
            *out_val = buf[pos++] ? 1 : 0;
        } else {
            *out_val = 0;
        }
    } else {
        *out_val = 0;
    }

    return (int)pos;
}

int main() {
    printf("imola-bridge: Starting Arduino Router RPC Bridge Responder with OpenOCD HW backend...\n");
    fflush(stdout);

    // Connect to OpenOCD daemon
    for (int retry = 0; retry < 10; retry++) {
        g_openocd_fd = connect_openocd();
        if (g_openocd_fd >= 0) break;
        printf("imola-bridge: Waiting for OpenOCD at %s:%d...\n", OPENOCD_HOST, OPENOCD_PORT);
        sleep(1);
    }
    if (g_openocd_fd >= 0) {
        printf("imola-bridge: Connected to OpenOCD daemon!\n");
        init_stm32_hw();
    } else {
        fprintf(stderr, "imola-bridge: Warning: Could not connect to OpenOCD at %s:%d\n", OPENOCD_HOST, OPENOCD_PORT);
    }

    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("socket");
        return 1;
    }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, ROUTER_SOCKET_PATH, sizeof(addr.sun_path) - 1);

    for (int retry = 0; retry < 15; retry++) {
        if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
            break;
        }
        printf("imola-bridge: Waiting for %s...\n", ROUTER_SOCKET_PATH);
        sleep(1);
    }
    printf("imola-bridge: Connected to %s\n", ROUTER_SOCKET_PATH);
    fflush(stdout);

    // Register set_pin_by_name: [0, 1, "$/register", ["set_pin_by_name"]]
    unsigned char reg_pkt[] = {
        0x94, 0x00, 0x01, 0xaa,
        '$', '/', 'r', 'e', 'g', 'i', 's', 't', 'e', 'r',
        0x91, 0xaf,
        's', 'e', 't', '_', 'p', 'i', 'n', '_', 'b', 'y', '_', 'n', 'a', 'm', 'e'
    };

    if (write(sock, reg_pkt, sizeof(reg_pkt)) < 0) {
        perror("write register");
        close(sock);
        return 1;
    }

    unsigned char buf[4096];
    ssize_t n = read(sock, buf, sizeof(buf));
    if (n <= 0) {
        fprintf(stderr, "imola-bridge: Failed to read register response\n");
        close(sock);
        return 1;
    }
    printf("imola-bridge: Registered 'set_pin_by_name' successfully!\n");
    fflush(stdout);

    // Main robust request loop
    size_t buf_pos = 0;
    while (1) {
        if (sizeof(buf) - buf_pos > 0) {
            n = read(sock, buf + buf_pos, sizeof(buf) - buf_pos);
            if (n <= 0) {
                printf("imola-bridge: Router disconnected (n=%zd, errno=%d)\n", n, errno);
                break;
            }
            buf_pos += (size_t)n;
        }

        // Process all complete messages currently in buffer
        while (buf_pos > 0) {
            uint32_t msg_id = 0;
            char method[32] = {0};
            char pin[32] = {0};
            int val = 0;

            int consumed = parse_rpc_request(buf, buf_pos, &msg_id,
                                            method, sizeof(method),
                                            pin, sizeof(pin), &val);

            if (consumed == 0) {
                // Incomplete message; wait for more data from read()
                break;
            } else if (consumed < 0) {
                // Protocol sync error: find next 0x94 0x00
                size_t skip = 1;
                while (skip + 1 < buf_pos && !(buf[skip] == 0x94 && buf[skip + 1] == 0x00)) {
                    skip++;
                }
                printf("imola-bridge: Resyncing stream, skipping %zu corrupted bytes\n", skip);
                memmove(buf, buf + skip, buf_pos - skip);
                buf_pos -= skip;
                continue;
            }

            printf(">>> [RPC REQUEST] id=%u %s('%s', %d)\n", msg_id, method, pin, val);

            // Execute hardware action
            if (strcmp(method, "set_pin_by_name") == 0) {
                execute_pin_action(pin, val);
            }

            // Encode response: [1, msg_id, null, true]
            unsigned char resp_pkt[16];
            size_t rlen = 0;
            resp_pkt[rlen++] = 0x94; // fixarray of 4
            resp_pkt[rlen++] = 0x01; // RESPONSE
            if (msg_id <= 0x7f) {
                resp_pkt[rlen++] = (unsigned char)msg_id;
            } else if (msg_id <= 0xff) {
                resp_pkt[rlen++] = 0xcc;
                resp_pkt[rlen++] = (unsigned char)msg_id;
            } else if (msg_id <= 0xffff) {
                resp_pkt[rlen++] = 0xcd;
                resp_pkt[rlen++] = (unsigned char)(msg_id >> 8);
                resp_pkt[rlen++] = (unsigned char)(msg_id & 0xff);
            } else {
                resp_pkt[rlen++] = 0xce;
                resp_pkt[rlen++] = (unsigned char)(msg_id >> 24);
                resp_pkt[rlen++] = (unsigned char)((msg_id >> 16) & 0xff);
                resp_pkt[rlen++] = (unsigned char)((msg_id >> 8) & 0xff);
                resp_pkt[rlen++] = (unsigned char)(msg_id & 0xff);
            }
            resp_pkt[rlen++] = 0xc0; // null (no error)
            resp_pkt[rlen++] = 0xc3; // true (success result)

            if (write(sock, resp_pkt, rlen) < 0) {
                perror("write response");
                goto cleanup;
            }
            printf("<<< [RPC SUCCESS] id=%u responded.\n", msg_id);
            fflush(stdout);

            // Consume processed message from stream buffer
            memmove(buf, buf + consumed, buf_pos - consumed);
            buf_pos -= (size_t)consumed;
        }
    }

cleanup:
    if (g_openocd_fd >= 0) close(g_openocd_fd);
    close(sock);
    return 0;
}
