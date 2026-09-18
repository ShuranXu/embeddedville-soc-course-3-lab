#include "soc.h"

static volatile uint32_t elapsed_tenths;
static volatile uint32_t running;
static volatile uint32_t display_dirty = 1u;

static uint32_t encode_mmss_t(uint32_t tenths)
{
  /* TODO(gpio-sevenseg): return five packed BCD nibbles in MMSS.t order. */
  (void)tenths;
  return 0u;
}

void Timer_IRQHandler(void)
{
  /* TODO(interrupt-integration): acknowledge first, accept a tick only while
     running, update shared state, and emit the matching UART evidence byte. */
}

void GPIO_IRQHandler(void)
{
  /* TODO(interrupt-integration): snapshot causes once, apply RESET before
     START/PAUSE, acknowledge accepted bits, and emit R/S/P evidence. */
}

int main(void)
{
  gpio_enable_events(SOC_GPIO_START_PAUSE | SOC_GPIO_RESET);
  timer_configure(100000u);
  for (;;) {
    if (display_dirty != 0u) {
      display_dirty = 0u;
      display_write(encode_mmss_t(elapsed_tenths));
    }
    cpu_wait_for_interrupt();
  }
}
