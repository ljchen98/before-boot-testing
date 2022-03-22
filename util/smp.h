// See LICENSE.Sifive for license details.
#ifndef SIFIVE_SMP
#define SIFIVE_SMP
#include "platform.h"

// The maximum number of HARTs this code supports
#ifndef MAX_HARTS
#define MAX_HARTS 128 // 改成最大支持 128 个核
#endif
#define CLINT_END_HART_IPI CLINT_CTRL_ADDR + (MAX_HARTS*4)
#define CLINT1_END_HART_IPI CLINT1_CTRL_ADDR + (MAX_HARTS*4)
#define SYN_ADDR CLINT_END_HART_IPI // 定义这个地址为一个公共空间，用于多核的同步
#define SYN_ADDR_END SYN_ADDR + (MAX_HARTS*4)

// The hart that non-SMP tests should run on
#ifndef NONSMP_HART
#define NONSMP_HART 0
#endif

/* If your test cannot handle multiple-threads, use this:
 *   smp_disable(reg1)
 */
#define smp_disable(reg1, reg2)			 \
  csrr reg1, mhartid				;\
  li   reg2, NONSMP_HART			;\
  beq  reg1, reg2, hart0_entry			;\
42:						;\
  wfi    					;\
  j 42b						;\
hart0_entry:

/* If your test needs to temporarily block multiple-threads, do this:
 *    smp_pause(reg1, reg2)
 *    ... single-threaded work ...
 *    smp_resume(reg1, reg2)
 *    ... multi-threaded work ...
 */

/* Version 3.0: 
 *     smp_pause 用于暂停一些 (实际上是放入等待中断状态) 不希望运行的 hart。
 *     这里修改了 smp_pause, 使其能够让多达两个 (可以扩展到四个) hart 不停止。
 *     32 位的 reg1，从低到高每 8 位代表需要不停止的 hart。这 8 位中，0~254 代表 hard id。255 代表无效。 (注意！不能有大于等于 255 个 hart!!)
 *     例如：reg1 = 11111111 11111111 00000011 00000000 代表 hart 0 和 3 不停止。
 */
#define smp_pause(reg1, reg2, reg3)	 \
  li reg2, 0x8			 ;\
  csrw mie, reg2		 ;\
  csrr reg3, mhartid		;\
  andi reg2, reg1, 0xff; \
  beq  reg2, reg3, 40f;\
  srli reg1, reg1, 8; \
  andi reg2, reg1, 0xff; \
  beq  reg2, reg3, 40f; \
  j 42f ;\
40:


#ifdef CLINT1_CTRL_ADDR
// If a second CLINT exists, then make sure we:
// 1) Trigger a software interrupt on all harts of both CLINTs.
// 2) Locate your own hart's software interrupt pending register and clear it.
// 3) Wait for all harts on both CLINTs to clear their software interrupt
//    pending register.
// WARNING: This code makes these assumptions, which are only true for Fadu as
// of now:
// 1) hart0 uses CLINT0 at offset 0
// 2) hart2 uses CLINT1 at offset 0
// 3) hart3 uses CLINT1 at offset 1
// 4) There are no other harts or CLINTs in the system.
#define smp_resume(reg1, reg2)	 \
  /* Trigger software interrupt on CLINT0 */ \
  li reg1, CLINT_CTRL_ADDR	;\
41:				;\
  li reg2, 1			;\
  sw reg2, 0(reg1)		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT_END_HART_IPI	;\
  blt reg1, reg2, 41b		;\
  /* Trigger software interrupt on CLINT1 */ \
  li reg1, CLINT1_CTRL_ADDR	;\
41:				;\
  li reg2, 1			;\
  sw reg2, 0(reg1)		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT1_END_HART_IPI	;\
  blt reg1, reg2, 41b		;\
  /* Wait to receive software interrupt */ \
42:				;\
  wfi    			;\
  csrr reg2, mip		;\
  andi reg2, reg2, 0x8		;\
  beqz reg2, 42b		;\
  /* Clear own software interrupt bit */ \
  csrr reg2, mhartid		;\
  bnez reg2, 41f; \
  /* hart0 case: Use CLINT0 */ \
  li reg1, CLINT_CTRL_ADDR	;\
  slli reg2, reg2, 2		;\
  add reg2, reg2, reg1		;\
  sw zero, 0(reg2)		;\
  j 42f; \
41: \
  /* hart 2, 3 case: Use CLINT1 and remap hart IDs to 0 and 1 */ \
  li reg1, CLINT1_CTRL_ADDR	;\
  addi reg2, reg2, -2; \
  slli reg2, reg2, 2		;\
  add reg2, reg2, reg1		;\
  sw zero, 0(reg2)		; \
42: \
  /* Wait for all software interrupt bits to be cleared on CLINT0 */ \
  li reg1, CLINT_CTRL_ADDR	;\
41:				;\
  lw reg2, 0(reg1)		;\
  bnez reg2, 41b		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT_END_HART_IPI	;\
  blt reg1, reg2, 41b; \
  /* Wait for all software interrupt bits to be cleared on CLINT1 */ \
  li reg1, CLINT1_CTRL_ADDR	;\
41:				;\
  lw reg2, 0(reg1)		;\
  bnez reg2, 41b		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT1_END_HART_IPI	;\
  blt reg1, reg2, 41b; \
  /* End smp_resume() */

#else

#define smp_resume(reg1, reg2)	 \
  li reg1, CLINT_CTRL_ADDR	;\
41:				;\
  li reg2, 1			;\
  sw reg2, 0(reg1)		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT_END_HART_IPI	;\
  blt reg1, reg2, 41b		;\
42:				;\
  wfi    			;\
  csrr reg2, mip		;\
  andi reg2, reg2, 0x8		;\
  beqz reg2, 42b		;\
  li reg1, CLINT_CTRL_ADDR	;\
  csrr reg2, mhartid		;\
  slli reg2, reg2, 2		;\
  add reg2, reg2, reg1		;\
  sw zero, 0(reg2)		;\
41:				;\
  lw reg2, 0(reg1)		;\
  bnez reg2, 41b		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT_END_HART_IPI	;\
  blt reg1, reg2, 41b


/* 双核的 smp_resume; reg1 同 smp_pause */
#define smp_resume_double(reg1, reg2, reg3)	 \
  /* 同步各个核心 */ \
  /* 当前核心先发出完成工作信号 */ \
  li reg3, SYN_ADDR ;\
  csrr reg2, mhartid ;\
  slli reg2, reg2, 2; \
  add reg3, reg3, reg2 ;\
  li reg2, 1; \
  sw reg2, 0(reg3);\
  /* 查看 hart1 是否到同步位置 */ \
  li reg3, SYN_ADDR ;\
  andi reg2, reg1, 0xff; \
  slli reg2, reg2, 2; \
  add reg3, reg3, reg2; \
40:    ;\
  lw reg2, 0(reg3); \
  beqz reg2, 40b; \
  /* 查看 hart2 是否到同步位置 */  \
  li reg3, SYN_ADDR ;\
  srli reg2, reg1, 8; \
  andi reg2, reg2, 0xff; \
  slli reg2, reg2, 2; \
  add reg3, reg3, reg2; \
40:    ;\
  lw reg2, 0(reg3); \
  beqz reg2, 40b; \
  /* 其中一个核心清除同步信号并触发软件中断 */ \
  csrr reg2, mhartid; \
  andi reg3, reg1, 0xff; \
  bne reg2, reg3, 42f; \
  /* 清除 */ \
  li reg3, SYN_ADDR; \
40:   ;\
  li reg2, 0; \
  sw reg2, 0(reg3); \
  addi reg3, reg3, 4; \
  li reg2, SYN_ADDR_END; \
  blt reg3, reg2, 40b ;\
  /* Trigger software interrupt on CLINT0 */ \
  li reg1, CLINT_CTRL_ADDR	;\
41:				;\
  li reg2, 1			;\
  sw reg2, 0(reg1)		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT_END_HART_IPI	;\
  blt reg1, reg2, 41b		;\
  /* Wait to receive software interrupt */ \
42:				;\
  wfi    			;\
  csrr reg2, mip		;\
  andi reg2, reg2, 0x8		;\
  beqz reg2, 42b		;\
  /* Clear own software interrupt bit */\
  li reg1, CLINT_CTRL_ADDR	;\
  csrr reg2, mhartid		;\
  slli reg2, reg2, 2		;\
  add reg2, reg2, reg1		;\
  sw zero, 0(reg2)		;\
  /* Wait for all software interrupt bits to be cleared on CLINT0 */ \
41:				;\
  lw reg2, 0(reg1)		;\
  bnez reg2, 41b		;\
  addi reg1, reg1, 4		;\
  li reg2, CLINT_END_HART_IPI	;\
  blt reg1, reg2, 41b

#endif  /* ifdef CLINT1_CTRL_ADDR */

#endif
