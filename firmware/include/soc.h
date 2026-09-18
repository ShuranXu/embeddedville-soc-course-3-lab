#ifndef EMBEDDEDVILLE_COURSE3_SOC_H
#define EMBEDDEDVILLE_COURSE3_SOC_H

#include <stdint.h>

#define SOC_TIMER_BASE   (0x40000000u)
#define SOC_GPIO_BASE    (0x40010000u)
#define SOC_DISPLAY_BASE (0x40020000u)
#define SOC_UART_BASE    (0x40030000u)

typedef struct { volatile uint32_t control, reload, value, status; } soc_timer_t;
typedef struct { volatile uint32_t data, direction, event, irq_enable; } soc_gpio_t;
typedef struct { volatile uint32_t digits, enable; } soc_display_t;
typedef struct { volatile uint32_t data, status; } soc_uart_t;

#define SOC_TIMER   ((soc_timer_t *)SOC_TIMER_BASE)
#define SOC_GPIO    ((soc_gpio_t *)SOC_GPIO_BASE)
#define SOC_DISPLAY ((soc_display_t *)SOC_DISPLAY_BASE)
#define SOC_UART    ((soc_uart_t *)SOC_UART_BASE)

enum {
  SOC_TIMER_ENABLE = 1u << 0,
  SOC_TIMER_PERIODIC = 1u << 1,
  SOC_TIMER_IRQ_ENABLE = 1u << 2,
  SOC_GPIO_START_PAUSE = 1u << 0,
  SOC_GPIO_RESET = 1u << 1,
  SOC_UART_TX_READY = 1u << 0,
};

void timer_configure(uint32_t reload);
void timer_acknowledge(void);
uint32_t gpio_events(void);
void gpio_acknowledge(uint32_t mask);
void gpio_enable_events(uint32_t mask);
void display_write(uint32_t packed_digits);
void uart_putc(char value);
void cpu_wait_for_interrupt(void);

#endif
