#include <platform.h>
#include <smp.h>
#include "common.h"
#include "testConfig.h"

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
// smp_pause 存在变更，使用说明请见 smp.h
  
// 初始化 UART
  li sp, (PAYLOAD_DEST + 0xffff000)
  li s1, 0xffffff00       // hart 0 不停止
  smp_pause(s1, s2, s10)
  call init_uart
  smp_resume(s1, s2)

  li s3, CORE_NUM 

// 单核检查
  li s6, 0xffffff00
  li s4, 0                    // i = 0  
single_core:
  add s1, s6, s4
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

// 核心对的检查
  li s6, 0xffffff00
  li s4, 0                  // i = 0
multi_core:
  li s5, 0                  // j = 0
multi_core_1:
  beq s4, s5, increase      // if i == j, jump to increase (cannot form a pair of cores)
  // One core i for notice and write
  add s1, s6, s4
  smp_pause(s1, s2, s10)
  mv a0, s4
  mv a1, s5
  call print_multi_core_info
  csrr a0, mhartid
  call multicore_mem_w
  smp_resume(s1, s2)
  // Another core j for read and check
  add s1, s6, s5
  smp_pause(s1, s2, s10)
  csrr a0, mhartid
  call multicore_mem_r
  smp_resume(s1, s2)
increase:    
  addi s5, s5, 1            // j++
  blt s5, s3, multi_core_1  // j < CORE_NUM
  addi s4, s4, 1            // i++
  blt s4, s3, multi_core    // i < CORE_NUM

// 多核 (这里为两核) 并行访问的检查 
  li s6, 0xffff0000         
  li s4, 0                  // i = 0
concurrency:
  li s5, 0                  // j = 0
concurrency_1:
  beq s4, s5, increase_con  // if i == j, jump to increase (cannot form a pair of cores)
  // core i & j concurrently write
  add s1, s6, s4
  sll s7, s5, 8
  add s8, s1, s7 
  mv  s1, s8
  smp_pause(s1, s2, s10)
  mv a0, s4
  mv a1, s5
  call print_concurrently_core_info
  csrr a0, mhartid
  mv a1, s8
  call concurrent_mem_cross_w 
  mv s1, s8
  smp_resume_double(s1, s2, s10)
  // core k reads and checks
  li s7, 0                // k = 0
check_1:
  li s1, 0xffffff00
  add s1, s1, s7
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

