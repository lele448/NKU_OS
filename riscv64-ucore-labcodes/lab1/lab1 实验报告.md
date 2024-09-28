# Lab 1

# 练习1：理解内核启动中的程序入口操作

## 一、实验内容：

阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明:

1.指令 la sp, bootstacktop 完成了什么操作，目的是什么？

2.tail kern_init 完成了什么操作，目的是什么？

## 二、实验过程：

下面是代码的完整内容：

```
#include <mmu.h>

#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry

kern_entry:

    la sp, bootstacktop

    tail kern_init

.section .data

   # .align 2^12

    .align PGSHIFT
    .global bootstack

bootstack:

    .space KSTACKSIZE
    .global bootstacktop

bootstacktop:
```

***

1.**指令 la sp, bootstacktop 完成了什么操作，目的是什么？**

首先，***这条指令完成了将bookstacktop的地址加载到堆栈指针中，即分配好内核栈。***具体来说如下：

**la：**是“load address”指令，用于将符号地址加载到寄存器中。

**sp：** 堆栈指针寄存器，用于指向当前栈的栈顶。

**bookstacktop：** 查看下面的代码段可知，它是.data段的一个全局符号。

**目的：**将栈指针寄存器sp改为.data段的结束地址。在进入内核初始化之前，将栈指针设置到一个安全的内核栈空间的顶部，并为内核启动过程提供栈空间，为后续代码的执行提供一个有效的堆栈环境。

2.**tail kern_init 完成了什么操作，目的是什么？**

对于该指令，***完成了函数跳转操作，跳转到 `kern_init` 函数并直接执行它的代码，同时避免保存当前的返回地址。*** 具体来说如下：

**tail：**`tail` 指令是 "tail-call" 优化的一种实现，它直接跳转到指定的目标函数（`kern_init`），而不保留当前函数的返回地址。

**kern_init：** 内核初始化函数标签，也是“真正的”内核入口点。

**目的：** 首先tail优化了函数的调用，避免保存返回地址和栈操作。但最主要的目的是进入内核初始化函数并开始内核的初始化操作。

# 练习2：完善中断处理

## 一、实验内容：

请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

## 二、实验过程：

**完善后的代码**：

```完善后的代码
  case IRQ_S_TIMER:
        // "All bits besides SSIP and USIP in the sip register are
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
         /* LAB1 EXERCISE2   YOUR CODE :  */
         clock_set_next_event();//发生这次时钟中断的时候，我们要设置下一次时钟中断
        if (++ticks % TICK_NUM == 0) {
            print_ticks();
            num++;           //打印计数器+1        
        }
         if(num==10){
             sbi_shutdown();
         } 

        break; 
        //2211774
```

**实验结果**

![1](D:\大二作业\操作系统\NKU_OS\riscv64-ucore-labcodes\lab1\1.png)

**实现过程和定时器中断中断处理的流程：**

要实现这个功能，我们需要在trap.c中的interrupt_handler函数中处理时钟中断。当遇到时钟中断时，我们需要更新计数器ticks，并在每次增加100次后调用print_ticks函数打印信息。同时，我们需要记录打印次数num，当num达到10时，调用sbi_shutdown()函数关机。



# 扩展练习 Challenge1：描述与理解中断流程

## 一、实验内容：

描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

## 二、实验过程：

**ucore中处理中断异常的流程（从异常的产生开始）**：

1. **异常产生**：当CPU检测到异常时（如硬件故障、软件错误等），会生成一个异常信号。

2. **保存现场**：CPU会自动执行以下操作：

   将当前的程序计数器（PC）值压入栈中，以保存返回地址。

   将当前的程序状态寄存器（PSR）压入栈中，以保存处理器的状态信息。

   将当前的通用寄存器（GPR）集合压入栈中，以保存当前进程的上下文。

3. **中断向量表查询**：CPU会根据异常类型查找中断向量表（IVT），找到对应的中断服务例程（ISR）入口地址。

4. **执行中断服务例程**：CPU跳转到ISR的起始地址，开始执行ISR。在ISR中，操作系统会进一步处理异常，例如恢复现场、记录日志、调度其他进程等。

5. **恢复现场**：ISR执行完毕后，CPU会从栈中弹出之前保存的PC、PSR和GPR，恢复到异常发生前的状态。

6. **继续执行**：CPU继续执行被中断的指令或调度新的进程/线程运行。

**mov a0，sp的目的:**
sp是栈顶指针,它现在存了36个寄存器的信息,定义为一个结构体trapframe.所以该指令意思为把结构体trapframe的地址传给a0寄存器，而a0寄存器会传递作为trap（）函数的参数。

**SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？**

在uCore中处理中断异常时，SAVE_ALL宏中的寄存器保存在栈中的位置是由trapframe结构体定义的。trapframe结构体包含了所有需要保存的寄存器，以及它们在栈中的位置信息。具体来说，trapframe结构体中的pushregs子结构体定义了通用寄存器的保存顺序和位置，而其他寄存器（如状态寄存器、错误码寄存器等）则直接跟在pushregs之后，按照特定的顺序压入栈中。

**对于任何中断，__alltraps 中都需要保存所有寄存器吗？**

对于任何中断，__alltraps中是否需要保存所有寄存器，这取决于具体的实现和需求。一般来说，当进入中断处理程序时，应该保存可能会被中断处理程序修改的所有寄存器。这样可以确保在中断处理程序执行完毕后，能够正确地恢复原始程序的上下文。然而，在某些情况下，可能不需要保存所有的寄存器，特别是那些在中断处理过程中不会被修改的寄存器。这样做可以减少保存和恢复寄存器的开销，提高中断处理的效率。但是，具体实现时应根据系统的需求和安全性要求来决定是否保存所有寄存器。

# 扩增练习 Challenge2：理解上下文切换机制

## 一、实验内容：

在trapentry.S中汇编代码：

1.csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

2.save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

## 二、实验过程：

1.**csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？**

（1）**csrw sscratch, sp：**

该指令实现了***将sp的值赋给sscratch***的操作。

**目的：**将当前的堆栈指针 (`sp`) 值保存到 CSR `sscratch` 中。在中断或异常处理过程中，操作系统或内核通常需要一个临时保存的栈指针，这样可以在终中断处理过程中改变栈指针，而不丢失原来的栈顶位置。`sscratch` 作为一个临时寄存器，允许操作系统在发生中断或异常时将 `sp` 临时保存起来，稍后可以恢复。

（2）**csrrw s0, sscratch, x0**

该指令完成了***将  `sscratch` 中的当前值读取，并保存到寄存器 `s0` 中。将寄存器 `x0` 的值（始终为 0）写入  `sscratch`，将 `sscratch` 置0***的操作。

***目的：*** 通过将 `sscratch` 的值存入 `s0`，程序可以在异常或中断处理期间保存当前的上下文状态（即 `sscratch` 的内容）。将 `sscratch` 清零（写入0），这在递归异常发生时非常重要。这样，处理异常的代码可以检查 `sscratch` 的值，以确定当前是否已处于内核模式，避免错误处理或死锁。

2.**save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？**

首先，`stval` 的作用是：记录一些中断处理所需要的辅助信息，比如指令获取(instruction fetch)、访存、缺页异常，它会把发生问题的目标地址或者出错的指令记录下来，这样我们在中断处理程序中就知道处理目标了。

而`scause` 的作用是记录中断发生的原因，还会记录该中断是不是一个外部中断。

由上述可知，这些都是在完成陷入后无意义的寄存器，没有还原的必要。

虽然他们在中断完成后无意义，但在异常发生时，`stval` 和 `scause` 提供了关于异常原因的重要信息。保存这些值允许开发者在调试或分析异常时查看当时的状态，帮助定位问题。而且如果系统在处理异常时崩溃，保存的 CSR 值可以用于后续的错误日志分析，帮助开发者了解异常发生前的系统状态。同时这些寄存器会被保存下来作为参数传给 `trap` 函数，保证其正确地去处理异常。

# lab1 扩展练习3：完善异常中断

## 一、实验内容：

编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。（

二、实验过程：

**打开NKU_OS\riscv64-ucore-labcodes\lab1\kern\trap\trap.c：**

```c
void exception_handler(struct trapframe *tf) {
uint32_t instr;  // 声明一个变量用于存储指令
    instr = *(uint16_t *)(tf->epc);  // 从epc地址读取16位（2字节）的指令
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            // 更新epc寄存器以跳过异常指令
            if ((instr & 0x3) != 0x3) {
                // 2字节压缩指令
                tf->epc += 2;
            } else {
                // 4字节标准指令
                tf->epc += 4;
            }
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
	    cprintf("Exception type: Breakpoint\n");
            cprintf("ebreak caught at 0x%08x\n", tf->epc);
            // 更新epc寄存器以跳过断点指令
            if ((instr & 0x3) != 0x3) {
                // 2字节压缩指令
                tf->epc += 2;
            } else {
                // 4字节指令
                tf->epc += 4;
            }
            break;
			…… ……
    }
}

```

其中，在 RISC-V 架构中，标准指令（32 位，4 字节）必须以最低 2 位为 `11`，即 `instr & 0x3 == 0x3`。这意味着如果最低 2 位不是 `11`，则该指令是压缩指令（16 位，2 字节）。

为了查看输出是否正确，继续编码触发异常，在kern.c修改kern_init函数：

```c
int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
cons_init();  // init the console

const char *message = "(THU.CST) os is loading ...\n";
cprintf("%s\n\n", message);

print_kerninfo();

// grade_backtrace();

idt_init();  // init interrupt descriptor table

// rdtime in mbare mode crashes
clock_init();  // init clock interrupt

intr_enable();  // enable irq interrupt

	asm volatile (
"mret"
);
asm volatile (
	"ebreak"
);
while (1)
    ;
}
```

查看编码是否正确：

![2](D:\大二作业\操作系统\NKU_OS\riscv64-ucore-labcodes\lab1\2.jpg)

![2](D:\大二作业\操作系统\NKU_OS\riscv64-ucore-labcodes\lab1\2.jpg)
