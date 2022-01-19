#include <platform.h>
#include <smp.h>
#include "common.h"
#include "testConfig.h"

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
// Use Version 2.0 of smp_pause(reg1, reg2) & smp_resume(reg1, reg2):
// Each bit of reg1 provided to smp_pause indicates which hartid would not pause
// E.g. reg1 = 0000 1001 means that hartid 0 & 3 would not pause  
  
// initialize UART
  li sp, (PAYLOAD_DEST + 0xffff000)
  li s1, 1                     // 0000 0001: assume hartid 0 not pause
  smp_pause(s1, s2, s10)
  call init_uart
  smp_resume(s1, s2)

  li s3, CORE_NUM 

// Check each single core
  li s6, 1
  li s4, 0                    // i = 0  
single_core:
  sll s1, s6, s4
  smp_pause(s1, s2, s10)
  csrr a0, mhartid
  call singlecore_mem_wr_B2B
  csrr a0, mhartid
  call singlecore_mem_wr_nonB2B
  csrr a0, mhartid
  call singlecore_mem_Bit_wr_B2B
  csrr a0, mhartid
  call singlecore_mem_Bit_wr_nonB2B
  smp_resume(s1, s2)
  addi s4, s4, 1            // i++
  blt s4, s3, single_core   // i < CORE_NUM

// Check the communication of each pair of cores
  li s6, 1
  li s4, 0                  // i = 0
multi_core:
  li s5, 0                  // j = 0
multi_core_1:
  beq s4, s5, increase      // if i == j, jump to increase (cannot form a pair of cores)
  // One core i for notice and write
  sll s1, s6, s4
  smp_pause(s1, s2, s10)
  mv a0, s4
  mv a1, s5
  call print_multi_core_info
  csrr a0, mhartid
  call multicore_mem_w
  smp_resume(s1, s2)
  // Another core j for read and check
  sll s1, s6, s5
  smp_pause(s1, s2, s10)
  csrr a0, mhartid
  call multicore_mem_r
  smp_resume(s1, s2)
increase:    
  addi s5, s5, 1            // j++
  blt s5, s3, multi_core_1  // j < CORE_NUM
  addi s4, s4, 1            // i++
  blt s4, s3, multi_core    // i < CORE_NUM

// Check the concurrency of multiple cores (two cores)
  li s6, 1                  // s6 is always 1 used for left shift
  li s4, 0                  // i = 0
concurrency:
  li s5, 0                  // j = 0
concurrency_1:
  beq s4, s5, increase_con  // if i == j, jump to increase (cannot form a pair of cores)
  // core i & j concurrently write
  sll s1, s6, s4
  sll s7, s6, s5
  or  s8, s1, s7            // s8 is indicating which core(s) not pause, e.g. 0000 1001 means that hartid 0 & 3 would not pause
  mv  s1, s8
  smp_pause(s1, s2, s10)
  mv a0, s4
  mv a1, s5
  call print_concurrently_core_info
  csrr a0, mhartid
  mv a1, s8
  call concurrent_mem_cross_w 
  smp_resume(s1, s2)
  // core k reads and checks
  li s7, 0                // k = 0
check_1:
  sll s1, s6, s7
  smp_pause(s1, s2, s10)
  csrr a0, mhartid
  mv a1, s8
  call concurrent_mem_cross_r
  smp_resume(s1, s2)
  addi s7, s7, 1            // k++
  blt s7, s3, check_1       // k < CORE_NUM
increase_con:    
  addi s5, s5, 1            // j++
  blt s5, s3, concurrency_1 // j < CORE_NUM
  addi s4, s4, 1            // i++
  blt s4, s3, concurrency   // i < CORE_NUM

// Other stuff before start system
  li s1, 1                  // 0000 0001: assume hartid 0 not pause
  smp_pause(s1, s2, s10)
  li sp, (PAYLOAD_DEST + 0xffff000)
  call main
  smp_resume(s1, s2)
  csrr a0, mhartid // hartid for next level bootloader
  la a1, dtb // dtb address for next level bootloader
  li s1, PAYLOAD_DEST
  jr s1
  
  .section .dtb
  .align 3
dtb:

