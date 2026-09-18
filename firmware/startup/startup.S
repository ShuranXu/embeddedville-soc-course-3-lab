.syntax unified
.cpu cortex-m0
.thumb

.extern main
.extern _sidata
.extern _sdata
.extern _edata
.extern _sbss
.extern _ebss
.extern _stack_top

.section .vectors, "a", %progbits
.align 2
.global g_vector_table
g_vector_table:
  .word _stack_top
  .word Reset_Handler
  .word NMI_Handler
  .word HardFault_Handler
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0
  .word SVC_Handler
  .word 0
  .word 0
  .word PendSV_Handler
  .word SysTick_Handler
  .word Timer_IRQHandler
  .word GPIO_IRQHandler

.section .text.Reset_Handler, "ax", %progbits
.thumb_func
.global Reset_Handler
Reset_Handler:
  ldr r0, =_sidata
  ldr r1, =_sdata
  ldr r2, =_edata
1: cmp r1, r2
  bcs 2f
  ldr r3, [r0]
  adds r0, #4
  str r3, [r1]
  adds r1, #4
  b 1b
2: ldr r1, =_sbss
  ldr r2, =_ebss
  movs r3, #0
3: cmp r1, r2
  bcs 4f
  str r3, [r1]
  adds r1, #4
  b 3b
4: bl main
5: b 5b

.section .text.Default_Handler, "ax", %progbits
.thumb_func
.global Default_Handler
Default_Handler: b .

.macro weak_handler name
  .weak \name
  .thumb_set \name, Default_Handler
.endm
weak_handler NMI_Handler
weak_handler HardFault_Handler
weak_handler SVC_Handler
weak_handler PendSV_Handler
weak_handler SysTick_Handler
weak_handler Timer_IRQHandler
weak_handler GPIO_IRQHandler
