# Lab 4

## 练习1：分配并初始化一个进程控制块（需要编码）

> `alloc_proc`函数（位于`kern/process/proc.c`中）负责分配并返回一个新的`struct` `proc_struct`结构，用于存储新建立的内核线程的管理信息。`ucore`需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
>
> > 【提示】在`alloc_proc`函数的实现中，需要初始化的`proc_struct`结构中的成员变量至少包括：`state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name`。
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请说明`proc_struct`中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

在编写初始化代码之前，在 `kern/process/proc.h` 文件中可以看到进程控制块的结构体定义：

```
struct proc_struct {
    enum proc_state state;                      // Process state
    int pid;                                    // Process ID
    int runs;                                   // the running times of Proces
    uintptr_t kstack;                           // Process kernel stack
    volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;                 // the parent process
    struct mm_struct *mm;                       // Process's memory management field
    struct context context;                     // Switch here to run process
    struct trapframe *tf;                       // Trap frame for current interrupt
    uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
    uint32_t flags;                             // Process flag
    char name[PROC_NAME_LEN + 1];               // Process name
    list_entry_t list_link;                     // Process link list 
    list_entry_t hash_link;                     // Process hash list
};
```

 而其中，`state` 在之前已经被定义：

```
enum proc_state {
    PROC_UNINIT = 0,  // uninitialized
    PROC_SLEEPING,    // sleeping
    PROC_RUNNABLE,    // runnable(maybe running)
    PROC_ZOMBIE,      // almost dead, and wait parent proc to reclaim his resource
};
```

因此在初始化时，`state` 应该初始化为`PROC_UNINIT` 表示“未初始化”状态。

除此之外需要注意的是`cr3` ，它用来保存页表所在的基址，在之前的`pmm_init` 里面我们曾初始化过页表基址，并赋值给`boot_cr3` 。

具体的实现代码见下：

```
proc->state = PROC_UNINIT;               
proc->pid = -1;               // PID 默认为 -1，表示尚未分配          
proc->runs = 0;               // 进程运行次数初始化为 0           
proc->kstack = 0;             // 内核栈指针为空
proc->need_resched = false;   // 默认不需要重新调度           
proc->parent = NULL;          // 父进程指针为空          
proc->mm = NULL;              // 内存管理结构体指针为空           
memset(&(proc->context), 0, sizeof(struct context));   // 初始化上下文为零
proc->tf = NULL;              // 中断帧指针为空          
proc->cr3 = boot_cr3;                     
proc->flags = 0;              // 标志位初始化为 0          
memset(proc->name, 0, PROC_NAME_LEN);   // 进程名初始化为空字符串
```

`struct context context` 中保存了进程执行的上下文，也就是几个关键的寄存器的值。这些寄存器的值用于在进程切换中还原之前进程的运行状态。

```
struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};
```

`struct trapframe *tf`是进程的中断帧，当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中。系统调用可能会改变用户寄存器的值，我们可以通过调整中断帧来使得系统调用返回特定的值。

```
struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t badvaddr;
    uintptr_t cause;
};
```





## 练习二

### 代码实现

按照实验手册上的流程，逐步调用相关函数，补充各参数。这里额外添加了一些必要的步骤：

+ `proc->parent = current;`：将新线程的父线程设置为`current`
+ `proc->pid = pid;`：将获取的线程`pid`赋给新线程的`pid`
+ `nr_process++;`：线程数量自增1

```c
proc = alloc_proc();
proc->parent = current;
setup_kstack(proc);
copy_mm(clone_flags, proc);
copy_thread(proc, stack, tf);
int pid = get_pid();
proc->pid = pid;
hash_proc(proc);
list_add(&proc_list, &(proc->list_link));
nr_process++;
proc->state = PROC_RUNNABLE;
ret = proc->pid;
```

### 问题解答

`ucore`能做到给每个新`fork`的线程一个唯一的`id`。在这里通过`get_pid`分配`id`，它的原理是对于一个可能分配出去的`last_id`，遍历线程链表，判断是否有`id`与之相等的线程，如果有，则将`last_id`自增1，且保证自增之后不会与当前查询过的线程`id`冲突，并且其不会超过最大的线程数，重新从头开始遍历链表。如果没有，则更新下一个可能冲突的线程`id`。

通过这种算法，只有一个`id`在与所有线程链表中的`id`均不相同时才能分配出去，所以可以做到给每个新`fork`的线程一个唯一的`id`。



## 练习3：编写proc_run 函数（需要编码）

> proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：
>
> - 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
> - 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
> - 切换当前进程为要运行的进程。
> - 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
> - 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
> - 允许中断。
>
> 请回答如下问题：
>
> - 在本实验的执行过程中，创建且运行了几个内核线程？

```c++
// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void proc_run(struct proc_struct *proc) {
    if (proc != current) {//进程不是当前进程，则切换
        // LAB4:EXERCISE3 2213787
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
       //禁用中断
       //切换当前进程为要运行的进程
       struct proc_struct *from=current;
       struct proc_struct *to=proc;
       bool intr_flag;
       ////禁用中断，以免进程切换时被中断
       local_intr_save(intr_flag);
        {//切换进程
            current = proc;
         

​        lcr3(to->cr3);//切换页表，以便使用新进程的地址空间
​        switch_to(&(from->context), &(to->context));//上下文切换
​    }
​    //中断恢复
​    local_intr_restore(intr_flag);
}

}
```



proc_run用于将指定的进程切换到CPU上运行,即该函数是在进行进程切换时被使用到的。为了更好地理解进程切换的整个流程，可以从proc_init()开始观察：

在proc_inits()中调用了alloc_proc函数，在alloc_proc函数中通过kmalloc函数获得proc_struct结构的一块内存块并进行初步初始化（即把proc_struct中的各个成员变量清零）。

```c++
void
proc_init(void) {
    int i;
    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }
    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }
    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
/*这段代码检查了 idleproc 进程结构体的多个字段是否符合初始化的预期状态：
    cr3 == boot_cr3：检查进程的页表基址是否为 boot_cr3，即指向内核的页表。
    tf == NULL：检查进程的陷阱帧 tf 是否为空，表明还没有运行过用户代码。
    state == PROC_UNINIT：检查进程的状态是否为未初始化。
    pid == -1：进程ID应该为-1，表示尚未分配有效的进程ID。
    其他字段检查是否为零或空值，确保进程还没有完全初始化。*/
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");

    }
    
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process ++;

    current = idleproc;//当前线程为idleproc

    //创建并初始化 init 进程，调用 kernel_thread() 创建一个新线程
    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

```

- idleproc->pid = 0;表明了该线程是第0个内核线程，相当于定义了这个内核线程的id
- idleproc->state = PROC_RUNNABLE;改变了其状态，相当于该线程现在被创建后处于就绪状态了
- idleproc->kstack = (uintptr_t)bootstack;设置了其所使用的内核栈的起始地址
- idleproc->need_resched = 1;后面cpu_idle函数会用（只要此标志为1，马上就调用schedule函数要求调度器切换其他进程执行）

-    set_proc_name(idleproc, "idle");设置进程名称为 `"idle"`

在该函数中调用了kernel_thread函数，使用该函数创建一个新线程

```c++
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
 // 对trameframe，也就是我们程序的一些上下文进行一些初始化
  struct trapframe tf;
  memset(&tf, 0, sizeof(struct trapframe));
  // 设置内核线程的参数和函数指针
  tf.gpr.s0 = (uintptr_t)fn;
  tf.gpr.s1 = (uintptr_t)arg;
    
  // 设置 trapframe 中的 status 寄存器（SSTATUS）
  // SSTATUS_SPP：Supervisor Previous Privilege（设置为 supervisor 模式，因为这是一个内核线程）
  // SSTATUS_SPIE：Supervisor Previous Interrupt Enable（设置为启用中断，因为这是一个内核线程）
  // SSTATUS_SIE：Supervisor Interrupt Enable（设置为禁用中断，因为我们不希望该线程被中断）
  tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    
  // 将入口点（epc）设置为 kernel_thread_entry 函数，作用实际上是将pc指针指向它(*trapentry.S会用到)
  tf.epc = (uintptr_t)kernel_thread_entry;
  // 使用 do_fork 创建一个新进程（内核线程），这样才真正用设置的tf创建新进程。
  return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```

首先给tf进行清零初始化，随后设置设置内核线程的参数和函数指针。对tf.status赋值时，读取sstatus寄存器的值，然后根据特定的位操作，设置SPP和SPIE位，并同时清除SIE位，从而实现特权级别切换、保留中断使能状态并禁用中断的操作。

在这个函数中采用了局部变量tf来放置保存内核线程的临时中断帧，并把中断帧的指针传递给do_fork函数，而do_fork函数会调用copy_thread函数来在新创建的进程内核栈上专门给进程的中断帧分配一块空间。

do_fork是创建线程的主要函数。kernel_thread函数通过调用do_fork函数最终完成了内核线程的创建工作。在do_fork函数中会分配并初始化进制控制块，即使用`alloc_proc`函数，所以在此说明又分配了一块空间给新的内核线程。**所以当proc_init函数结束时，已经有两个内核线程了，即proc线程和init线程。**



## 扩展练习 Challenge：  

> 说明语句 local_intr_save(intr_flag);....local_intr_restore(intr_flag); 是如何实现开 关中断的？

```c++
#define local_intr_save(x) 
  do {          
    x = __intr_save(); 
  } while (0)
#define local_intr_restore(x) __intr_restore(x);
```

```c++
static inline bool __intr_save(void) {
  if (read_csr(sstatus) & SSTATUS_SIE) {
    intr_disable();
    return 1;
  }
  return 0;
}
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
```

`__intr_save` 函数用于保存当前的中断状态，并且禁用中断。sstatus寄存器中包含中断相关的标志位，所以需要读取它，并且看当前是否允许外部中断（SSTATUS_SIE），如果允许就禁用中断，防止当前函数执行过程中被中断打断。`return 1;`表示原本允许中断，现在禁用中断，返回 1；如果中断已经被禁用（即 `SSTATUS_SIE` 位未设置），则直接返回 0，表示没有改变中断状态。

**`__intr_restore` 函数**是根据传入的flag恢复中断状态，而根据宏定义我们可以知道，flag是之前由__intr_save函数返回的值，表示原本的中断状态。如果flag为1，表示之前中断是被禁用的，则恢复中断。

综上，当调用`local_intr_save(intr_flag)`时，就会禁用中断，并将中断的当前状态（是否允许中断）保存在intr_flag中。

- 如果 `SSTATUS_SIE` 被设置（即允许中断），`__intr_save()` 会禁用中断，并返回 `1`。
- 如果 `SSTATUS_SIE` 没有被设置（即中断已禁用），`__intr_save()` 返回 `0`。

当调用local_intr_restore(intr_flag)时，会根据传入的intr_flag的值恢复中断状态：

- 如果intr_flag为1（表示之前允许中断），则调用intr_enable()恢复中断

- 如果intr_flag为0（表示之前中断被禁用），则不做任何改变