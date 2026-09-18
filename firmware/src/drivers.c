#include "soc.h"

void timer_configure(uint32_t reload)
{
  SOC_TIMER->reload = reload;
  SOC_TIMER->status = 1u;
  SOC_TIMER->control = SOC_TIMER_ENABLE | SOC_TIMER_PERIODIC | SOC_TIMER_IRQ_ENABLE;
}

void timer_acknowledge(void) { SOC_TIMER->status = 1u; }
uint32_t gpio_events(void) { return SOC_GPIO->event; }
void gpio_acknowledge(uint32_t mask) { SOC_GPIO->event = mask; }
void gpio_enable_events(uint32_t mask) { SOC_GPIO->irq_enable = mask; }
void display_write(uint32_t packed_digits) { SOC_DISPLAY->digits = packed_digits; SOC_DISPLAY->enable = 0x1Fu; }

void uart_putc(char value)
{
  while ((SOC_UART->status & SOC_UART_TX_READY) == 0u) { }
  SOC_UART->data = (uint32_t)(uint8_t)value;
}

void cpu_wait_for_interrupt(void) { __asm volatile ("wfi" ::: "memory"); }
