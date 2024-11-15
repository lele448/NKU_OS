
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000a517          	auipc	a0,0xa
ffffffffc0200036:	00e50513          	addi	a0,a0,14 # ffffffffc020a040 <ide>
ffffffffc020003a:	00011617          	auipc	a2,0x11
ffffffffc020003e:	53660613          	addi	a2,a2,1334 # ffffffffc0211570 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	6bf030ef          	jal	ra,ffffffffc0203f08 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020004e:	00004597          	auipc	a1,0x4
ffffffffc0200052:	38a58593          	addi	a1,a1,906 # ffffffffc02043d8 <etext+0x4>
ffffffffc0200056:	00004517          	auipc	a0,0x4
ffffffffc020005a:	3a250513          	addi	a0,a0,930 # ffffffffc02043f8 <etext+0x24>
ffffffffc020005e:	05c000ef          	jal	ra,ffffffffc02000ba <cprintf>

    print_kerninfo();
ffffffffc0200062:	0fc000ef          	jal	ra,ffffffffc020015e <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc0200066:	779000ef          	jal	ra,ffffffffc0200fde <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006a:	4fa000ef          	jal	ra,ffffffffc0200564 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020006e:	7b3010ef          	jal	ra,ffffffffc0202020 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200072:	35e000ef          	jal	ra,ffffffffc02003d0 <ide_init>
    swap_init();                // init swap
ffffffffc0200076:	650020ef          	jal	ra,ffffffffc02026c6 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007a:	3ac000ef          	jal	ra,ffffffffc0200426 <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc020007e:	a001                	j	ffffffffc020007e <kern_init+0x4c>

ffffffffc0200080 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200080:	1141                	addi	sp,sp,-16
ffffffffc0200082:	e022                	sd	s0,0(sp)
ffffffffc0200084:	e406                	sd	ra,8(sp)
ffffffffc0200086:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200088:	3f0000ef          	jal	ra,ffffffffc0200478 <cons_putc>
    (*cnt) ++;
ffffffffc020008c:	401c                	lw	a5,0(s0)
}
ffffffffc020008e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200090:	2785                	addiw	a5,a5,1
ffffffffc0200092:	c01c                	sw	a5,0(s0)
}
ffffffffc0200094:	6402                	ld	s0,0(sp)
ffffffffc0200096:	0141                	addi	sp,sp,16
ffffffffc0200098:	8082                	ret

ffffffffc020009a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009a:	1101                	addi	sp,sp,-32
ffffffffc020009c:	862a                	mv	a2,a0
ffffffffc020009e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	00000517          	auipc	a0,0x0
ffffffffc02000a4:	fe050513          	addi	a0,a0,-32 # ffffffffc0200080 <cputch>
ffffffffc02000a8:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ac:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ae:	6f1030ef          	jal	ra,ffffffffc0203f9e <vprintfmt>
    return cnt;
}
ffffffffc02000b2:	60e2                	ld	ra,24(sp)
ffffffffc02000b4:	4532                	lw	a0,12(sp)
ffffffffc02000b6:	6105                	addi	sp,sp,32
ffffffffc02000b8:	8082                	ret

ffffffffc02000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ba:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000bc:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c0:	8e2a                	mv	t3,a0
ffffffffc02000c2:	f42e                	sd	a1,40(sp)
ffffffffc02000c4:	f832                	sd	a2,48(sp)
ffffffffc02000c6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c8:	00000517          	auipc	a0,0x0
ffffffffc02000cc:	fb850513          	addi	a0,a0,-72 # ffffffffc0200080 <cputch>
ffffffffc02000d0:	004c                	addi	a1,sp,4
ffffffffc02000d2:	869a                	mv	a3,t1
ffffffffc02000d4:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	ec06                	sd	ra,24(sp)
ffffffffc02000d8:	e0ba                	sd	a4,64(sp)
ffffffffc02000da:	e4be                	sd	a5,72(sp)
ffffffffc02000dc:	e8c2                	sd	a6,80(sp)
ffffffffc02000de:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e0:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e2:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	6bb030ef          	jal	ra,ffffffffc0203f9e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e8:	60e2                	ld	ra,24(sp)
ffffffffc02000ea:	4512                	lw	a0,4(sp)
ffffffffc02000ec:	6125                	addi	sp,sp,96
ffffffffc02000ee:	8082                	ret

ffffffffc02000f0 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f0:	a661                	j	ffffffffc0200478 <cons_putc>

ffffffffc02000f2 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f2:	1141                	addi	sp,sp,-16
ffffffffc02000f4:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000f6:	3b6000ef          	jal	ra,ffffffffc02004ac <cons_getc>
ffffffffc02000fa:	dd75                	beqz	a0,ffffffffc02000f6 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02000fc:	60a2                	ld	ra,8(sp)
ffffffffc02000fe:	0141                	addi	sp,sp,16
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200102:	00011317          	auipc	t1,0x11
ffffffffc0200106:	3f630313          	addi	t1,t1,1014 # ffffffffc02114f8 <is_panic>
ffffffffc020010a:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020010e:	715d                	addi	sp,sp,-80
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	f436                	sd	a3,40(sp)
ffffffffc0200116:	f83a                	sd	a4,48(sp)
ffffffffc0200118:	fc3e                	sd	a5,56(sp)
ffffffffc020011a:	e0c2                	sd	a6,64(sp)
ffffffffc020011c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020011e:	020e1a63          	bnez	t3,ffffffffc0200152 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200122:	4785                	li	a5,1
ffffffffc0200124:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200128:	8432                	mv	s0,a2
ffffffffc020012a:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020012c:	862e                	mv	a2,a1
ffffffffc020012e:	85aa                	mv	a1,a0
ffffffffc0200130:	00004517          	auipc	a0,0x4
ffffffffc0200134:	2d050513          	addi	a0,a0,720 # ffffffffc0204400 <etext+0x2c>
    va_start(ap, fmt);
ffffffffc0200138:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020013a:	f81ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    vcprintf(fmt, ap);
ffffffffc020013e:	65a2                	ld	a1,8(sp)
ffffffffc0200140:	8522                	mv	a0,s0
ffffffffc0200142:	f59ff0ef          	jal	ra,ffffffffc020009a <vcprintf>
    cprintf("\n");
ffffffffc0200146:	00005517          	auipc	a0,0x5
ffffffffc020014a:	06a50513          	addi	a0,a0,106 # ffffffffc02051b0 <commands+0xb60>
ffffffffc020014e:	f6dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200152:	39c000ef          	jal	ra,ffffffffc02004ee <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200156:	4501                	li	a0,0
ffffffffc0200158:	130000ef          	jal	ra,ffffffffc0200288 <kmonitor>
    while (1) {
ffffffffc020015c:	bfed                	j	ffffffffc0200156 <__panic+0x54>

ffffffffc020015e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020015e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200160:	00004517          	auipc	a0,0x4
ffffffffc0200164:	2c050513          	addi	a0,a0,704 # ffffffffc0204420 <etext+0x4c>
void print_kerninfo(void) {
ffffffffc0200168:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016a:	f51ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020016e:	00000597          	auipc	a1,0x0
ffffffffc0200172:	ec458593          	addi	a1,a1,-316 # ffffffffc0200032 <kern_init>
ffffffffc0200176:	00004517          	auipc	a0,0x4
ffffffffc020017a:	2ca50513          	addi	a0,a0,714 # ffffffffc0204440 <etext+0x6c>
ffffffffc020017e:	f3dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200182:	00004597          	auipc	a1,0x4
ffffffffc0200186:	25258593          	addi	a1,a1,594 # ffffffffc02043d4 <etext>
ffffffffc020018a:	00004517          	auipc	a0,0x4
ffffffffc020018e:	2d650513          	addi	a0,a0,726 # ffffffffc0204460 <etext+0x8c>
ffffffffc0200192:	f29ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200196:	0000a597          	auipc	a1,0xa
ffffffffc020019a:	eaa58593          	addi	a1,a1,-342 # ffffffffc020a040 <ide>
ffffffffc020019e:	00004517          	auipc	a0,0x4
ffffffffc02001a2:	2e250513          	addi	a0,a0,738 # ffffffffc0204480 <etext+0xac>
ffffffffc02001a6:	f15ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001aa:	00011597          	auipc	a1,0x11
ffffffffc02001ae:	3c658593          	addi	a1,a1,966 # ffffffffc0211570 <end>
ffffffffc02001b2:	00004517          	auipc	a0,0x4
ffffffffc02001b6:	2ee50513          	addi	a0,a0,750 # ffffffffc02044a0 <etext+0xcc>
ffffffffc02001ba:	f01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001be:	00011597          	auipc	a1,0x11
ffffffffc02001c2:	7b158593          	addi	a1,a1,1969 # ffffffffc021196f <end+0x3ff>
ffffffffc02001c6:	00000797          	auipc	a5,0x0
ffffffffc02001ca:	e6c78793          	addi	a5,a5,-404 # ffffffffc0200032 <kern_init>
ffffffffc02001ce:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001dc:	95be                	add	a1,a1,a5
ffffffffc02001de:	85a9                	srai	a1,a1,0xa
ffffffffc02001e0:	00004517          	auipc	a0,0x4
ffffffffc02001e4:	2e050513          	addi	a0,a0,736 # ffffffffc02044c0 <etext+0xec>
}
ffffffffc02001e8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ea:	bdc1                	j	ffffffffc02000ba <cprintf>

ffffffffc02001ec <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ec:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ee:	00004617          	auipc	a2,0x4
ffffffffc02001f2:	30260613          	addi	a2,a2,770 # ffffffffc02044f0 <etext+0x11c>
ffffffffc02001f6:	04e00593          	li	a1,78
ffffffffc02001fa:	00004517          	auipc	a0,0x4
ffffffffc02001fe:	30e50513          	addi	a0,a0,782 # ffffffffc0204508 <etext+0x134>
void print_stackframe(void) {
ffffffffc0200202:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200204:	effff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200208 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	00004617          	auipc	a2,0x4
ffffffffc020020e:	31660613          	addi	a2,a2,790 # ffffffffc0204520 <etext+0x14c>
ffffffffc0200212:	00004597          	auipc	a1,0x4
ffffffffc0200216:	32e58593          	addi	a1,a1,814 # ffffffffc0204540 <etext+0x16c>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	32e50513          	addi	a0,a0,814 # ffffffffc0204548 <etext+0x174>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200222:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200224:	e97ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200228:	00004617          	auipc	a2,0x4
ffffffffc020022c:	33060613          	addi	a2,a2,816 # ffffffffc0204558 <etext+0x184>
ffffffffc0200230:	00004597          	auipc	a1,0x4
ffffffffc0200234:	35058593          	addi	a1,a1,848 # ffffffffc0204580 <etext+0x1ac>
ffffffffc0200238:	00004517          	auipc	a0,0x4
ffffffffc020023c:	31050513          	addi	a0,a0,784 # ffffffffc0204548 <etext+0x174>
ffffffffc0200240:	e7bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200244:	00004617          	auipc	a2,0x4
ffffffffc0200248:	34c60613          	addi	a2,a2,844 # ffffffffc0204590 <etext+0x1bc>
ffffffffc020024c:	00004597          	auipc	a1,0x4
ffffffffc0200250:	36458593          	addi	a1,a1,868 # ffffffffc02045b0 <etext+0x1dc>
ffffffffc0200254:	00004517          	auipc	a0,0x4
ffffffffc0200258:	2f450513          	addi	a0,a0,756 # ffffffffc0204548 <etext+0x174>
ffffffffc020025c:	e5fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    }
    return 0;
}
ffffffffc0200260:	60a2                	ld	ra,8(sp)
ffffffffc0200262:	4501                	li	a0,0
ffffffffc0200264:	0141                	addi	sp,sp,16
ffffffffc0200266:	8082                	ret

ffffffffc0200268 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200268:	1141                	addi	sp,sp,-16
ffffffffc020026a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026c:	ef3ff0ef          	jal	ra,ffffffffc020015e <print_kerninfo>
    return 0;
}
ffffffffc0200270:	60a2                	ld	ra,8(sp)
ffffffffc0200272:	4501                	li	a0,0
ffffffffc0200274:	0141                	addi	sp,sp,16
ffffffffc0200276:	8082                	ret

ffffffffc0200278 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200278:	1141                	addi	sp,sp,-16
ffffffffc020027a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027c:	f71ff0ef          	jal	ra,ffffffffc02001ec <print_stackframe>
    return 0;
}
ffffffffc0200280:	60a2                	ld	ra,8(sp)
ffffffffc0200282:	4501                	li	a0,0
ffffffffc0200284:	0141                	addi	sp,sp,16
ffffffffc0200286:	8082                	ret

ffffffffc0200288 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200288:	7115                	addi	sp,sp,-224
ffffffffc020028a:	ed5e                	sd	s7,152(sp)
ffffffffc020028c:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	00004517          	auipc	a0,0x4
ffffffffc0200292:	33250513          	addi	a0,a0,818 # ffffffffc02045c0 <etext+0x1ec>
kmonitor(struct trapframe *tf) {
ffffffffc0200296:	ed86                	sd	ra,216(sp)
ffffffffc0200298:	e9a2                	sd	s0,208(sp)
ffffffffc020029a:	e5a6                	sd	s1,200(sp)
ffffffffc020029c:	e1ca                	sd	s2,192(sp)
ffffffffc020029e:	fd4e                	sd	s3,184(sp)
ffffffffc02002a0:	f952                	sd	s4,176(sp)
ffffffffc02002a2:	f556                	sd	s5,168(sp)
ffffffffc02002a4:	f15a                	sd	s6,160(sp)
ffffffffc02002a6:	e962                	sd	s8,144(sp)
ffffffffc02002a8:	e566                	sd	s9,136(sp)
ffffffffc02002aa:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ac:	e0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b0:	00004517          	auipc	a0,0x4
ffffffffc02002b4:	33850513          	addi	a0,a0,824 # ffffffffc02045e8 <etext+0x214>
ffffffffc02002b8:	e03ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc02002bc:	000b8563          	beqz	s7,ffffffffc02002c6 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c0:	855e                	mv	a0,s7
ffffffffc02002c2:	48c000ef          	jal	ra,ffffffffc020074e <print_trapframe>
ffffffffc02002c6:	00004c17          	auipc	s8,0x4
ffffffffc02002ca:	38ac0c13          	addi	s8,s8,906 # ffffffffc0204650 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002ce:	00005917          	auipc	s2,0x5
ffffffffc02002d2:	6ea90913          	addi	s2,s2,1770 # ffffffffc02059b8 <commands+0x1368>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d6:	00004497          	auipc	s1,0x4
ffffffffc02002da:	33a48493          	addi	s1,s1,826 # ffffffffc0204610 <etext+0x23c>
        if (argc == MAXARGS - 1) {
ffffffffc02002de:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e0:	00004b17          	auipc	s6,0x4
ffffffffc02002e4:	338b0b13          	addi	s6,s6,824 # ffffffffc0204618 <etext+0x244>
        argv[argc ++] = buf;
ffffffffc02002e8:	00004a17          	auipc	s4,0x4
ffffffffc02002ec:	258a0a13          	addi	s4,s4,600 # ffffffffc0204540 <etext+0x16c>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4a8d                	li	s5,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002f2:	854a                	mv	a0,s2
ffffffffc02002f4:	02c040ef          	jal	ra,ffffffffc0204320 <readline>
ffffffffc02002f8:	842a                	mv	s0,a0
ffffffffc02002fa:	dd65                	beqz	a0,ffffffffc02002f2 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fc:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200300:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200302:	e1bd                	bnez	a1,ffffffffc0200368 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200304:	fe0c87e3          	beqz	s9,ffffffffc02002f2 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	6582                	ld	a1,0(sp)
ffffffffc020030a:	00004d17          	auipc	s10,0x4
ffffffffc020030e:	346d0d13          	addi	s10,s10,838 # ffffffffc0204650 <commands>
        argv[argc ++] = buf;
ffffffffc0200312:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200314:	4401                	li	s0,0
ffffffffc0200316:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200318:	3bd030ef          	jal	ra,ffffffffc0203ed4 <strcmp>
ffffffffc020031c:	c919                	beqz	a0,ffffffffc0200332 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031e:	2405                	addiw	s0,s0,1
ffffffffc0200320:	0b540063          	beq	s0,s5,ffffffffc02003c0 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200324:	000d3503          	ld	a0,0(s10)
ffffffffc0200328:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	3a9030ef          	jal	ra,ffffffffc0203ed4 <strcmp>
ffffffffc0200330:	f57d                	bnez	a0,ffffffffc020031e <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200332:	00141793          	slli	a5,s0,0x1
ffffffffc0200336:	97a2                	add	a5,a5,s0
ffffffffc0200338:	078e                	slli	a5,a5,0x3
ffffffffc020033a:	97e2                	add	a5,a5,s8
ffffffffc020033c:	6b9c                	ld	a5,16(a5)
ffffffffc020033e:	865e                	mv	a2,s7
ffffffffc0200340:	002c                	addi	a1,sp,8
ffffffffc0200342:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200346:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200348:	fa0555e3          	bgez	a0,ffffffffc02002f2 <kmonitor+0x6a>
}
ffffffffc020034c:	60ee                	ld	ra,216(sp)
ffffffffc020034e:	644e                	ld	s0,208(sp)
ffffffffc0200350:	64ae                	ld	s1,200(sp)
ffffffffc0200352:	690e                	ld	s2,192(sp)
ffffffffc0200354:	79ea                	ld	s3,184(sp)
ffffffffc0200356:	7a4a                	ld	s4,176(sp)
ffffffffc0200358:	7aaa                	ld	s5,168(sp)
ffffffffc020035a:	7b0a                	ld	s6,160(sp)
ffffffffc020035c:	6bea                	ld	s7,152(sp)
ffffffffc020035e:	6c4a                	ld	s8,144(sp)
ffffffffc0200360:	6caa                	ld	s9,136(sp)
ffffffffc0200362:	6d0a                	ld	s10,128(sp)
ffffffffc0200364:	612d                	addi	sp,sp,224
ffffffffc0200366:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200368:	8526                	mv	a0,s1
ffffffffc020036a:	389030ef          	jal	ra,ffffffffc0203ef2 <strchr>
ffffffffc020036e:	c901                	beqz	a0,ffffffffc020037e <kmonitor+0xf6>
ffffffffc0200370:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200374:	00040023          	sb	zero,0(s0)
ffffffffc0200378:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037a:	d5c9                	beqz	a1,ffffffffc0200304 <kmonitor+0x7c>
ffffffffc020037c:	b7f5                	j	ffffffffc0200368 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020037e:	00044783          	lbu	a5,0(s0)
ffffffffc0200382:	d3c9                	beqz	a5,ffffffffc0200304 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200384:	033c8963          	beq	s9,s3,ffffffffc02003b6 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200388:	003c9793          	slli	a5,s9,0x3
ffffffffc020038c:	0118                	addi	a4,sp,128
ffffffffc020038e:	97ba                	add	a5,a5,a4
ffffffffc0200390:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200394:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200398:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039a:	e591                	bnez	a1,ffffffffc02003a6 <kmonitor+0x11e>
ffffffffc020039c:	b7b5                	j	ffffffffc0200308 <kmonitor+0x80>
ffffffffc020039e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a2:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a4:	d1a5                	beqz	a1,ffffffffc0200304 <kmonitor+0x7c>
ffffffffc02003a6:	8526                	mv	a0,s1
ffffffffc02003a8:	34b030ef          	jal	ra,ffffffffc0203ef2 <strchr>
ffffffffc02003ac:	d96d                	beqz	a0,ffffffffc020039e <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ae:	00044583          	lbu	a1,0(s0)
ffffffffc02003b2:	d9a9                	beqz	a1,ffffffffc0200304 <kmonitor+0x7c>
ffffffffc02003b4:	bf55                	j	ffffffffc0200368 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b6:	45c1                	li	a1,16
ffffffffc02003b8:	855a                	mv	a0,s6
ffffffffc02003ba:	d01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02003be:	b7e9                	j	ffffffffc0200388 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c0:	6582                	ld	a1,0(sp)
ffffffffc02003c2:	00004517          	auipc	a0,0x4
ffffffffc02003c6:	27650513          	addi	a0,a0,630 # ffffffffc0204638 <etext+0x264>
ffffffffc02003ca:	cf1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    return 0;
ffffffffc02003ce:	b715                	j	ffffffffc02002f2 <kmonitor+0x6a>

ffffffffc02003d0 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02003d0:	8082                	ret

ffffffffc02003d2 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56 //最大扇区数
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02003d2:	00253513          	sltiu	a0,a0,2
ffffffffc02003d6:	8082                	ret

ffffffffc02003d8 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02003d8:	03800513          	li	a0,56
ffffffffc02003dc:	8082                	ret

ffffffffc02003de <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;//数据在 ide 数组中的偏移量
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);//从ide数组中的iobase位置开始的数据复制到目的地址dst，nsecs * SECTSIZE 表示要复制的总字节数
ffffffffc02003de:	0000a797          	auipc	a5,0xa
ffffffffc02003e2:	c6278793          	addi	a5,a5,-926 # ffffffffc020a040 <ide>
    int iobase = secno * SECTSIZE;//数据在 ide 数组中的偏移量
ffffffffc02003e6:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02003ea:	1141                	addi	sp,sp,-16
ffffffffc02003ec:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);//从ide数组中的iobase位置开始的数据复制到目的地址dst，nsecs * SECTSIZE 表示要复制的总字节数
ffffffffc02003ee:	95be                	add	a1,a1,a5
ffffffffc02003f0:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02003f4:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);//从ide数组中的iobase位置开始的数据复制到目的地址dst，nsecs * SECTSIZE 表示要复制的总字节数
ffffffffc02003f6:	325030ef          	jal	ra,ffffffffc0203f1a <memcpy>
    return 0;
}
ffffffffc02003fa:	60a2                	ld	ra,8(sp)
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	0141                	addi	sp,sp,16
ffffffffc0200400:	8082                	ret

ffffffffc0200402 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,//ideno: 假设挂载了多块磁盘， 选择哪一块磁盘这里我们其实只有一块“ 磁盘” ， 这个参数就没用到
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200402:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200406:	0000a517          	auipc	a0,0xa
ffffffffc020040a:	c3a50513          	addi	a0,a0,-966 # ffffffffc020a040 <ide>
                   size_t nsecs) {
ffffffffc020040e:	1141                	addi	sp,sp,-16
ffffffffc0200410:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200412:	953e                	add	a0,a0,a5
ffffffffc0200414:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc0200418:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020041a:	301030ef          	jal	ra,ffffffffc0203f1a <memcpy>
    return 0;
}
ffffffffc020041e:	60a2                	ld	ra,8(sp)
ffffffffc0200420:	4501                	li	a0,0
ffffffffc0200422:	0141                	addi	sp,sp,16
ffffffffc0200424:	8082                	ret

ffffffffc0200426 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200426:	67e1                	lui	a5,0x18
ffffffffc0200428:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020042c:	00011717          	auipc	a4,0x11
ffffffffc0200430:	0cf73e23          	sd	a5,220(a4) # ffffffffc0211508 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200434:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200438:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	953e                	add	a0,a0,a5
ffffffffc020043c:	4601                	li	a2,0
ffffffffc020043e:	4881                	li	a7,0
ffffffffc0200440:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200444:	02000793          	li	a5,32
ffffffffc0200448:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	24c50513          	addi	a0,a0,588 # ffffffffc0204698 <commands+0x48>
    ticks = 0;
ffffffffc0200454:	00011797          	auipc	a5,0x11
ffffffffc0200458:	0a07b623          	sd	zero,172(a5) # ffffffffc0211500 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045c:	b9b9                	j	ffffffffc02000ba <cprintf>

ffffffffc020045e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020045e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200462:	00011797          	auipc	a5,0x11
ffffffffc0200466:	0a67b783          	ld	a5,166(a5) # ffffffffc0211508 <timebase>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	4581                	li	a1,0
ffffffffc020046e:	4601                	li	a2,0
ffffffffc0200470:	4881                	li	a7,0
ffffffffc0200472:	00000073          	ecall
ffffffffc0200476:	8082                	ret

ffffffffc0200478 <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200478:	100027f3          	csrr	a5,sstatus
ffffffffc020047c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020047e:	0ff57513          	zext.b	a0,a0
ffffffffc0200482:	e799                	bnez	a5,ffffffffc0200490 <cons_putc+0x18>
ffffffffc0200484:	4581                	li	a1,0
ffffffffc0200486:	4601                	li	a2,0
ffffffffc0200488:	4885                	li	a7,1
ffffffffc020048a:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020048e:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200490:	1101                	addi	sp,sp,-32
ffffffffc0200492:	ec06                	sd	ra,24(sp)
ffffffffc0200494:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200496:	058000ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc020049a:	6522                	ld	a0,8(sp)
ffffffffc020049c:	4581                	li	a1,0
ffffffffc020049e:	4601                	li	a2,0
ffffffffc02004a0:	4885                	li	a7,1
ffffffffc02004a2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004a6:	60e2                	ld	ra,24(sp)
ffffffffc02004a8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004aa:	a83d                	j	ffffffffc02004e8 <intr_enable>

ffffffffc02004ac <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ac:	100027f3          	csrr	a5,sstatus
ffffffffc02004b0:	8b89                	andi	a5,a5,2
ffffffffc02004b2:	eb89                	bnez	a5,ffffffffc02004c4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004b4:	4501                	li	a0,0
ffffffffc02004b6:	4581                	li	a1,0
ffffffffc02004b8:	4601                	li	a2,0
ffffffffc02004ba:	4889                	li	a7,2
ffffffffc02004bc:	00000073          	ecall
ffffffffc02004c0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02004c2:	8082                	ret
int cons_getc(void) {
ffffffffc02004c4:	1101                	addi	sp,sp,-32
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02004c8:	026000ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02004cc:	4501                	li	a0,0
ffffffffc02004ce:	4581                	li	a1,0
ffffffffc02004d0:	4601                	li	a2,0
ffffffffc02004d2:	4889                	li	a7,2
ffffffffc02004d4:	00000073          	ecall
ffffffffc02004d8:	2501                	sext.w	a0,a0
ffffffffc02004da:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02004dc:	00c000ef          	jal	ra,ffffffffc02004e8 <intr_enable>
}
ffffffffc02004e0:	60e2                	ld	ra,24(sp)
ffffffffc02004e2:	6522                	ld	a0,8(sp)
ffffffffc02004e4:	6105                	addi	sp,sp,32
ffffffffc02004e6:	8082                	ret

ffffffffc02004e8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004e8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004ec:	8082                	ret

ffffffffc02004ee <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004ee:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004f4:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004f8:	1141                	addi	sp,sp,-16
ffffffffc02004fa:	e022                	sd	s0,0(sp)
ffffffffc02004fc:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004fe:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200502:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200506:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200508:	05500613          	li	a2,85
ffffffffc020050c:	c399                	beqz	a5,ffffffffc0200512 <pgfault_handler+0x1e>
ffffffffc020050e:	04b00613          	li	a2,75
ffffffffc0200512:	11843703          	ld	a4,280(s0)
ffffffffc0200516:	47bd                	li	a5,15
ffffffffc0200518:	05700693          	li	a3,87
ffffffffc020051c:	00f70463          	beq	a4,a5,ffffffffc0200524 <pgfault_handler+0x30>
ffffffffc0200520:	05200693          	li	a3,82
ffffffffc0200524:	00004517          	auipc	a0,0x4
ffffffffc0200528:	19450513          	addi	a0,a0,404 # ffffffffc02046b8 <commands+0x68>
ffffffffc020052c:	b8fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200530:	00011517          	auipc	a0,0x11
ffffffffc0200534:	01053503          	ld	a0,16(a0) # ffffffffc0211540 <check_mm_struct>
ffffffffc0200538:	c911                	beqz	a0,ffffffffc020054c <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020053a:	11043603          	ld	a2,272(s0)
ffffffffc020053e:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200542:	6402                	ld	s0,0(sp)
ffffffffc0200544:	60a2                	ld	ra,8(sp)
ffffffffc0200546:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200548:	0b00206f          	j	ffffffffc02025f8 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020054c:	00004617          	auipc	a2,0x4
ffffffffc0200550:	18c60613          	addi	a2,a2,396 # ffffffffc02046d8 <commands+0x88>
ffffffffc0200554:	07800593          	li	a1,120
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	19850513          	addi	a0,a0,408 # ffffffffc02046f0 <commands+0xa0>
ffffffffc0200560:	ba3ff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200564 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200564:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200568:	00000797          	auipc	a5,0x0
ffffffffc020056c:	48878793          	addi	a5,a5,1160 # ffffffffc02009f0 <__alltraps>
ffffffffc0200570:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200574:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200578:	000407b7          	lui	a5,0x40
ffffffffc020057c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200580:	8082                	ret

ffffffffc0200582 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200582:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200584:	1141                	addi	sp,sp,-16
ffffffffc0200586:	e022                	sd	s0,0(sp)
ffffffffc0200588:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020058a:	00004517          	auipc	a0,0x4
ffffffffc020058e:	17e50513          	addi	a0,a0,382 # ffffffffc0204708 <commands+0xb8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200592:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200594:	b27ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200598:	640c                	ld	a1,8(s0)
ffffffffc020059a:	00004517          	auipc	a0,0x4
ffffffffc020059e:	18650513          	addi	a0,a0,390 # ffffffffc0204720 <commands+0xd0>
ffffffffc02005a2:	b19ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005a6:	680c                	ld	a1,16(s0)
ffffffffc02005a8:	00004517          	auipc	a0,0x4
ffffffffc02005ac:	19050513          	addi	a0,a0,400 # ffffffffc0204738 <commands+0xe8>
ffffffffc02005b0:	b0bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005b4:	6c0c                	ld	a1,24(s0)
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	19a50513          	addi	a0,a0,410 # ffffffffc0204750 <commands+0x100>
ffffffffc02005be:	afdff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005c2:	700c                	ld	a1,32(s0)
ffffffffc02005c4:	00004517          	auipc	a0,0x4
ffffffffc02005c8:	1a450513          	addi	a0,a0,420 # ffffffffc0204768 <commands+0x118>
ffffffffc02005cc:	aefff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005d0:	740c                	ld	a1,40(s0)
ffffffffc02005d2:	00004517          	auipc	a0,0x4
ffffffffc02005d6:	1ae50513          	addi	a0,a0,430 # ffffffffc0204780 <commands+0x130>
ffffffffc02005da:	ae1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005de:	780c                	ld	a1,48(s0)
ffffffffc02005e0:	00004517          	auipc	a0,0x4
ffffffffc02005e4:	1b850513          	addi	a0,a0,440 # ffffffffc0204798 <commands+0x148>
ffffffffc02005e8:	ad3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005ec:	7c0c                	ld	a1,56(s0)
ffffffffc02005ee:	00004517          	auipc	a0,0x4
ffffffffc02005f2:	1c250513          	addi	a0,a0,450 # ffffffffc02047b0 <commands+0x160>
ffffffffc02005f6:	ac5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005fa:	602c                	ld	a1,64(s0)
ffffffffc02005fc:	00004517          	auipc	a0,0x4
ffffffffc0200600:	1cc50513          	addi	a0,a0,460 # ffffffffc02047c8 <commands+0x178>
ffffffffc0200604:	ab7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200608:	642c                	ld	a1,72(s0)
ffffffffc020060a:	00004517          	auipc	a0,0x4
ffffffffc020060e:	1d650513          	addi	a0,a0,470 # ffffffffc02047e0 <commands+0x190>
ffffffffc0200612:	aa9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200616:	682c                	ld	a1,80(s0)
ffffffffc0200618:	00004517          	auipc	a0,0x4
ffffffffc020061c:	1e050513          	addi	a0,a0,480 # ffffffffc02047f8 <commands+0x1a8>
ffffffffc0200620:	a9bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200624:	6c2c                	ld	a1,88(s0)
ffffffffc0200626:	00004517          	auipc	a0,0x4
ffffffffc020062a:	1ea50513          	addi	a0,a0,490 # ffffffffc0204810 <commands+0x1c0>
ffffffffc020062e:	a8dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200632:	702c                	ld	a1,96(s0)
ffffffffc0200634:	00004517          	auipc	a0,0x4
ffffffffc0200638:	1f450513          	addi	a0,a0,500 # ffffffffc0204828 <commands+0x1d8>
ffffffffc020063c:	a7fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200640:	742c                	ld	a1,104(s0)
ffffffffc0200642:	00004517          	auipc	a0,0x4
ffffffffc0200646:	1fe50513          	addi	a0,a0,510 # ffffffffc0204840 <commands+0x1f0>
ffffffffc020064a:	a71ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020064e:	782c                	ld	a1,112(s0)
ffffffffc0200650:	00004517          	auipc	a0,0x4
ffffffffc0200654:	20850513          	addi	a0,a0,520 # ffffffffc0204858 <commands+0x208>
ffffffffc0200658:	a63ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020065c:	7c2c                	ld	a1,120(s0)
ffffffffc020065e:	00004517          	auipc	a0,0x4
ffffffffc0200662:	21250513          	addi	a0,a0,530 # ffffffffc0204870 <commands+0x220>
ffffffffc0200666:	a55ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020066a:	604c                	ld	a1,128(s0)
ffffffffc020066c:	00004517          	auipc	a0,0x4
ffffffffc0200670:	21c50513          	addi	a0,a0,540 # ffffffffc0204888 <commands+0x238>
ffffffffc0200674:	a47ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200678:	644c                	ld	a1,136(s0)
ffffffffc020067a:	00004517          	auipc	a0,0x4
ffffffffc020067e:	22650513          	addi	a0,a0,550 # ffffffffc02048a0 <commands+0x250>
ffffffffc0200682:	a39ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200686:	684c                	ld	a1,144(s0)
ffffffffc0200688:	00004517          	auipc	a0,0x4
ffffffffc020068c:	23050513          	addi	a0,a0,560 # ffffffffc02048b8 <commands+0x268>
ffffffffc0200690:	a2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200694:	6c4c                	ld	a1,152(s0)
ffffffffc0200696:	00004517          	auipc	a0,0x4
ffffffffc020069a:	23a50513          	addi	a0,a0,570 # ffffffffc02048d0 <commands+0x280>
ffffffffc020069e:	a1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006a2:	704c                	ld	a1,160(s0)
ffffffffc02006a4:	00004517          	auipc	a0,0x4
ffffffffc02006a8:	24450513          	addi	a0,a0,580 # ffffffffc02048e8 <commands+0x298>
ffffffffc02006ac:	a0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006b0:	744c                	ld	a1,168(s0)
ffffffffc02006b2:	00004517          	auipc	a0,0x4
ffffffffc02006b6:	24e50513          	addi	a0,a0,590 # ffffffffc0204900 <commands+0x2b0>
ffffffffc02006ba:	a01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006be:	784c                	ld	a1,176(s0)
ffffffffc02006c0:	00004517          	auipc	a0,0x4
ffffffffc02006c4:	25850513          	addi	a0,a0,600 # ffffffffc0204918 <commands+0x2c8>
ffffffffc02006c8:	9f3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006cc:	7c4c                	ld	a1,184(s0)
ffffffffc02006ce:	00004517          	auipc	a0,0x4
ffffffffc02006d2:	26250513          	addi	a0,a0,610 # ffffffffc0204930 <commands+0x2e0>
ffffffffc02006d6:	9e5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006da:	606c                	ld	a1,192(s0)
ffffffffc02006dc:	00004517          	auipc	a0,0x4
ffffffffc02006e0:	26c50513          	addi	a0,a0,620 # ffffffffc0204948 <commands+0x2f8>
ffffffffc02006e4:	9d7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006e8:	646c                	ld	a1,200(s0)
ffffffffc02006ea:	00004517          	auipc	a0,0x4
ffffffffc02006ee:	27650513          	addi	a0,a0,630 # ffffffffc0204960 <commands+0x310>
ffffffffc02006f2:	9c9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006f6:	686c                	ld	a1,208(s0)
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	28050513          	addi	a0,a0,640 # ffffffffc0204978 <commands+0x328>
ffffffffc0200700:	9bbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200704:	6c6c                	ld	a1,216(s0)
ffffffffc0200706:	00004517          	auipc	a0,0x4
ffffffffc020070a:	28a50513          	addi	a0,a0,650 # ffffffffc0204990 <commands+0x340>
ffffffffc020070e:	9adff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200712:	706c                	ld	a1,224(s0)
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	29450513          	addi	a0,a0,660 # ffffffffc02049a8 <commands+0x358>
ffffffffc020071c:	99fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200720:	746c                	ld	a1,232(s0)
ffffffffc0200722:	00004517          	auipc	a0,0x4
ffffffffc0200726:	29e50513          	addi	a0,a0,670 # ffffffffc02049c0 <commands+0x370>
ffffffffc020072a:	991ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020072e:	786c                	ld	a1,240(s0)
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	2a850513          	addi	a0,a0,680 # ffffffffc02049d8 <commands+0x388>
ffffffffc0200738:	983ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020073c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020073e:	6402                	ld	s0,0(sp)
ffffffffc0200740:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200742:	00004517          	auipc	a0,0x4
ffffffffc0200746:	2ae50513          	addi	a0,a0,686 # ffffffffc02049f0 <commands+0x3a0>
}
ffffffffc020074a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020074c:	b2bd                	j	ffffffffc02000ba <cprintf>

ffffffffc020074e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020074e:	1141                	addi	sp,sp,-16
ffffffffc0200750:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200752:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200754:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200756:	00004517          	auipc	a0,0x4
ffffffffc020075a:	2b250513          	addi	a0,a0,690 # ffffffffc0204a08 <commands+0x3b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020075e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200760:	95bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200764:	8522                	mv	a0,s0
ffffffffc0200766:	e1dff0ef          	jal	ra,ffffffffc0200582 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020076a:	10043583          	ld	a1,256(s0)
ffffffffc020076e:	00004517          	auipc	a0,0x4
ffffffffc0200772:	2b250513          	addi	a0,a0,690 # ffffffffc0204a20 <commands+0x3d0>
ffffffffc0200776:	945ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020077a:	10843583          	ld	a1,264(s0)
ffffffffc020077e:	00004517          	auipc	a0,0x4
ffffffffc0200782:	2ba50513          	addi	a0,a0,698 # ffffffffc0204a38 <commands+0x3e8>
ffffffffc0200786:	935ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020078a:	11043583          	ld	a1,272(s0)
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	2c250513          	addi	a0,a0,706 # ffffffffc0204a50 <commands+0x400>
ffffffffc0200796:	925ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020079a:	11843583          	ld	a1,280(s0)
}
ffffffffc020079e:	6402                	ld	s0,0(sp)
ffffffffc02007a0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a2:	00004517          	auipc	a0,0x4
ffffffffc02007a6:	2c650513          	addi	a0,a0,710 # ffffffffc0204a68 <commands+0x418>
}
ffffffffc02007aa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007ac:	90fff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc02007b0 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007b0:	11853783          	ld	a5,280(a0)
ffffffffc02007b4:	472d                	li	a4,11
ffffffffc02007b6:	0786                	slli	a5,a5,0x1
ffffffffc02007b8:	8385                	srli	a5,a5,0x1
ffffffffc02007ba:	06f76c63          	bltu	a4,a5,ffffffffc0200832 <interrupt_handler+0x82>
ffffffffc02007be:	00004717          	auipc	a4,0x4
ffffffffc02007c2:	37270713          	addi	a4,a4,882 # ffffffffc0204b30 <commands+0x4e0>
ffffffffc02007c6:	078a                	slli	a5,a5,0x2
ffffffffc02007c8:	97ba                	add	a5,a5,a4
ffffffffc02007ca:	439c                	lw	a5,0(a5)
ffffffffc02007cc:	97ba                	add	a5,a5,a4
ffffffffc02007ce:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007d0:	00004517          	auipc	a0,0x4
ffffffffc02007d4:	31050513          	addi	a0,a0,784 # ffffffffc0204ae0 <commands+0x490>
ffffffffc02007d8:	8e3ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007dc:	00004517          	auipc	a0,0x4
ffffffffc02007e0:	2e450513          	addi	a0,a0,740 # ffffffffc0204ac0 <commands+0x470>
ffffffffc02007e4:	8d7ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007e8:	00004517          	auipc	a0,0x4
ffffffffc02007ec:	29850513          	addi	a0,a0,664 # ffffffffc0204a80 <commands+0x430>
ffffffffc02007f0:	8cbff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007f4:	00004517          	auipc	a0,0x4
ffffffffc02007f8:	2ac50513          	addi	a0,a0,684 # ffffffffc0204aa0 <commands+0x450>
ffffffffc02007fc:	8bfff06f          	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200800:	1141                	addi	sp,sp,-16
ffffffffc0200802:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200804:	c5bff0ef          	jal	ra,ffffffffc020045e <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200808:	00011697          	auipc	a3,0x11
ffffffffc020080c:	cf868693          	addi	a3,a3,-776 # ffffffffc0211500 <ticks>
ffffffffc0200810:	629c                	ld	a5,0(a3)
ffffffffc0200812:	06400713          	li	a4,100
ffffffffc0200816:	0785                	addi	a5,a5,1
ffffffffc0200818:	02e7f733          	remu	a4,a5,a4
ffffffffc020081c:	e29c                	sd	a5,0(a3)
ffffffffc020081e:	cb19                	beqz	a4,ffffffffc0200834 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200820:	60a2                	ld	ra,8(sp)
ffffffffc0200822:	0141                	addi	sp,sp,16
ffffffffc0200824:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200826:	00004517          	auipc	a0,0x4
ffffffffc020082a:	2ea50513          	addi	a0,a0,746 # ffffffffc0204b10 <commands+0x4c0>
ffffffffc020082e:	88dff06f          	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc0200832:	bf31                	j	ffffffffc020074e <print_trapframe>
}
ffffffffc0200834:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200836:	06400593          	li	a1,100
ffffffffc020083a:	00004517          	auipc	a0,0x4
ffffffffc020083e:	2c650513          	addi	a0,a0,710 # ffffffffc0204b00 <commands+0x4b0>
}
ffffffffc0200842:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200844:	877ff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0200848 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200848:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc020084c:	1101                	addi	sp,sp,-32
ffffffffc020084e:	e822                	sd	s0,16(sp)
ffffffffc0200850:	ec06                	sd	ra,24(sp)
ffffffffc0200852:	e426                	sd	s1,8(sp)
ffffffffc0200854:	473d                	li	a4,15
ffffffffc0200856:	842a                	mv	s0,a0
ffffffffc0200858:	14f76a63          	bltu	a4,a5,ffffffffc02009ac <exception_handler+0x164>
ffffffffc020085c:	00004717          	auipc	a4,0x4
ffffffffc0200860:	4bc70713          	addi	a4,a4,1212 # ffffffffc0204d18 <commands+0x6c8>
ffffffffc0200864:	078a                	slli	a5,a5,0x2
ffffffffc0200866:	97ba                	add	a5,a5,a4
ffffffffc0200868:	439c                	lw	a5,0(a5)
ffffffffc020086a:	97ba                	add	a5,a5,a4
ffffffffc020086c:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc020086e:	00004517          	auipc	a0,0x4
ffffffffc0200872:	49250513          	addi	a0,a0,1170 # ffffffffc0204d00 <commands+0x6b0>
ffffffffc0200876:	845ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {//do_pgfault()页面置换成功时返回0
ffffffffc020087a:	8522                	mv	a0,s0
ffffffffc020087c:	c79ff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc0200880:	84aa                	mv	s1,a0
ffffffffc0200882:	12051b63          	bnez	a0,ffffffffc02009b8 <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200886:	60e2                	ld	ra,24(sp)
ffffffffc0200888:	6442                	ld	s0,16(sp)
ffffffffc020088a:	64a2                	ld	s1,8(sp)
ffffffffc020088c:	6105                	addi	sp,sp,32
ffffffffc020088e:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200890:	00004517          	auipc	a0,0x4
ffffffffc0200894:	2d050513          	addi	a0,a0,720 # ffffffffc0204b60 <commands+0x510>
}
ffffffffc0200898:	6442                	ld	s0,16(sp)
ffffffffc020089a:	60e2                	ld	ra,24(sp)
ffffffffc020089c:	64a2                	ld	s1,8(sp)
ffffffffc020089e:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008a0:	81bff06f          	j	ffffffffc02000ba <cprintf>
ffffffffc02008a4:	00004517          	auipc	a0,0x4
ffffffffc02008a8:	2dc50513          	addi	a0,a0,732 # ffffffffc0204b80 <commands+0x530>
ffffffffc02008ac:	b7f5                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	2f250513          	addi	a0,a0,754 # ffffffffc0204ba0 <commands+0x550>
ffffffffc02008b6:	b7cd                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008b8:	00004517          	auipc	a0,0x4
ffffffffc02008bc:	30050513          	addi	a0,a0,768 # ffffffffc0204bb8 <commands+0x568>
ffffffffc02008c0:	bfe1                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008c2:	00004517          	auipc	a0,0x4
ffffffffc02008c6:	30650513          	addi	a0,a0,774 # ffffffffc0204bc8 <commands+0x578>
ffffffffc02008ca:	b7f9                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	31c50513          	addi	a0,a0,796 # ffffffffc0204be8 <commands+0x598>
ffffffffc02008d4:	fe6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008d8:	8522                	mv	a0,s0
ffffffffc02008da:	c1bff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc02008de:	84aa                	mv	s1,a0
ffffffffc02008e0:	d15d                	beqz	a0,ffffffffc0200886 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008e2:	8522                	mv	a0,s0
ffffffffc02008e4:	e6bff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008e8:	86a6                	mv	a3,s1
ffffffffc02008ea:	00004617          	auipc	a2,0x4
ffffffffc02008ee:	31660613          	addi	a2,a2,790 # ffffffffc0204c00 <commands+0x5b0>
ffffffffc02008f2:	0ca00593          	li	a1,202
ffffffffc02008f6:	00004517          	auipc	a0,0x4
ffffffffc02008fa:	dfa50513          	addi	a0,a0,-518 # ffffffffc02046f0 <commands+0xa0>
ffffffffc02008fe:	805ff0ef          	jal	ra,ffffffffc0200102 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	31e50513          	addi	a0,a0,798 # ffffffffc0204c20 <commands+0x5d0>
ffffffffc020090a:	b779                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc020090c:	00004517          	auipc	a0,0x4
ffffffffc0200910:	32c50513          	addi	a0,a0,812 # ffffffffc0204c38 <commands+0x5e8>
ffffffffc0200914:	fa6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200918:	8522                	mv	a0,s0
ffffffffc020091a:	bdbff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc020091e:	84aa                	mv	s1,a0
ffffffffc0200920:	d13d                	beqz	a0,ffffffffc0200886 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200922:	8522                	mv	a0,s0
ffffffffc0200924:	e2bff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200928:	86a6                	mv	a3,s1
ffffffffc020092a:	00004617          	auipc	a2,0x4
ffffffffc020092e:	2d660613          	addi	a2,a2,726 # ffffffffc0204c00 <commands+0x5b0>
ffffffffc0200932:	0d400593          	li	a1,212
ffffffffc0200936:	00004517          	auipc	a0,0x4
ffffffffc020093a:	dba50513          	addi	a0,a0,-582 # ffffffffc02046f0 <commands+0xa0>
ffffffffc020093e:	fc4ff0ef          	jal	ra,ffffffffc0200102 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200942:	00004517          	auipc	a0,0x4
ffffffffc0200946:	30e50513          	addi	a0,a0,782 # ffffffffc0204c50 <commands+0x600>
ffffffffc020094a:	b7b9                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc020094c:	00004517          	auipc	a0,0x4
ffffffffc0200950:	32450513          	addi	a0,a0,804 # ffffffffc0204c70 <commands+0x620>
ffffffffc0200954:	b791                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	33a50513          	addi	a0,a0,826 # ffffffffc0204c90 <commands+0x640>
ffffffffc020095e:	bf2d                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200960:	00004517          	auipc	a0,0x4
ffffffffc0200964:	35050513          	addi	a0,a0,848 # ffffffffc0204cb0 <commands+0x660>
ffffffffc0200968:	bf05                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	36650513          	addi	a0,a0,870 # ffffffffc0204cd0 <commands+0x680>
ffffffffc0200972:	b71d                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200974:	00004517          	auipc	a0,0x4
ffffffffc0200978:	37450513          	addi	a0,a0,884 # ffffffffc0204ce8 <commands+0x698>
ffffffffc020097c:	f3eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200980:	8522                	mv	a0,s0
ffffffffc0200982:	b73ff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc0200986:	84aa                	mv	s1,a0
ffffffffc0200988:	ee050fe3          	beqz	a0,ffffffffc0200886 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020098c:	8522                	mv	a0,s0
ffffffffc020098e:	dc1ff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200992:	86a6                	mv	a3,s1
ffffffffc0200994:	00004617          	auipc	a2,0x4
ffffffffc0200998:	26c60613          	addi	a2,a2,620 # ffffffffc0204c00 <commands+0x5b0>
ffffffffc020099c:	0ea00593          	li	a1,234
ffffffffc02009a0:	00004517          	auipc	a0,0x4
ffffffffc02009a4:	d5050513          	addi	a0,a0,-688 # ffffffffc02046f0 <commands+0xa0>
ffffffffc02009a8:	f5aff0ef          	jal	ra,ffffffffc0200102 <__panic>
            print_trapframe(tf);
ffffffffc02009ac:	8522                	mv	a0,s0
}
ffffffffc02009ae:	6442                	ld	s0,16(sp)
ffffffffc02009b0:	60e2                	ld	ra,24(sp)
ffffffffc02009b2:	64a2                	ld	s1,8(sp)
ffffffffc02009b4:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009b6:	bb61                	j	ffffffffc020074e <print_trapframe>
                print_trapframe(tf);
ffffffffc02009b8:	8522                	mv	a0,s0
ffffffffc02009ba:	d95ff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009be:	86a6                	mv	a3,s1
ffffffffc02009c0:	00004617          	auipc	a2,0x4
ffffffffc02009c4:	24060613          	addi	a2,a2,576 # ffffffffc0204c00 <commands+0x5b0>
ffffffffc02009c8:	0f100593          	li	a1,241
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	d2450513          	addi	a0,a0,-732 # ffffffffc02046f0 <commands+0xa0>
ffffffffc02009d4:	f2eff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02009d8 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009d8:	11853783          	ld	a5,280(a0)
ffffffffc02009dc:	0007c363          	bltz	a5,ffffffffc02009e2 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009e0:	b5a5                	j	ffffffffc0200848 <exception_handler>
        interrupt_handler(tf);
ffffffffc02009e2:	b3f9                	j	ffffffffc02007b0 <interrupt_handler>
	...

ffffffffc02009f0 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02009f0:	14011073          	csrw	sscratch,sp
ffffffffc02009f4:	712d                	addi	sp,sp,-288
ffffffffc02009f6:	e406                	sd	ra,8(sp)
ffffffffc02009f8:	ec0e                	sd	gp,24(sp)
ffffffffc02009fa:	f012                	sd	tp,32(sp)
ffffffffc02009fc:	f416                	sd	t0,40(sp)
ffffffffc02009fe:	f81a                	sd	t1,48(sp)
ffffffffc0200a00:	fc1e                	sd	t2,56(sp)
ffffffffc0200a02:	e0a2                	sd	s0,64(sp)
ffffffffc0200a04:	e4a6                	sd	s1,72(sp)
ffffffffc0200a06:	e8aa                	sd	a0,80(sp)
ffffffffc0200a08:	ecae                	sd	a1,88(sp)
ffffffffc0200a0a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a0c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a0e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a10:	fcbe                	sd	a5,120(sp)
ffffffffc0200a12:	e142                	sd	a6,128(sp)
ffffffffc0200a14:	e546                	sd	a7,136(sp)
ffffffffc0200a16:	e94a                	sd	s2,144(sp)
ffffffffc0200a18:	ed4e                	sd	s3,152(sp)
ffffffffc0200a1a:	f152                	sd	s4,160(sp)
ffffffffc0200a1c:	f556                	sd	s5,168(sp)
ffffffffc0200a1e:	f95a                	sd	s6,176(sp)
ffffffffc0200a20:	fd5e                	sd	s7,184(sp)
ffffffffc0200a22:	e1e2                	sd	s8,192(sp)
ffffffffc0200a24:	e5e6                	sd	s9,200(sp)
ffffffffc0200a26:	e9ea                	sd	s10,208(sp)
ffffffffc0200a28:	edee                	sd	s11,216(sp)
ffffffffc0200a2a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a2c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a2e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a30:	fdfe                	sd	t6,248(sp)
ffffffffc0200a32:	14002473          	csrr	s0,sscratch
ffffffffc0200a36:	100024f3          	csrr	s1,sstatus
ffffffffc0200a3a:	14102973          	csrr	s2,sepc
ffffffffc0200a3e:	143029f3          	csrr	s3,stval
ffffffffc0200a42:	14202a73          	csrr	s4,scause
ffffffffc0200a46:	e822                	sd	s0,16(sp)
ffffffffc0200a48:	e226                	sd	s1,256(sp)
ffffffffc0200a4a:	e64a                	sd	s2,264(sp)
ffffffffc0200a4c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a4e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a50:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a52:	f87ff0ef          	jal	ra,ffffffffc02009d8 <trap>

ffffffffc0200a56 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a56:	6492                	ld	s1,256(sp)
ffffffffc0200a58:	6932                	ld	s2,264(sp)
ffffffffc0200a5a:	10049073          	csrw	sstatus,s1
ffffffffc0200a5e:	14191073          	csrw	sepc,s2
ffffffffc0200a62:	60a2                	ld	ra,8(sp)
ffffffffc0200a64:	61e2                	ld	gp,24(sp)
ffffffffc0200a66:	7202                	ld	tp,32(sp)
ffffffffc0200a68:	72a2                	ld	t0,40(sp)
ffffffffc0200a6a:	7342                	ld	t1,48(sp)
ffffffffc0200a6c:	73e2                	ld	t2,56(sp)
ffffffffc0200a6e:	6406                	ld	s0,64(sp)
ffffffffc0200a70:	64a6                	ld	s1,72(sp)
ffffffffc0200a72:	6546                	ld	a0,80(sp)
ffffffffc0200a74:	65e6                	ld	a1,88(sp)
ffffffffc0200a76:	7606                	ld	a2,96(sp)
ffffffffc0200a78:	76a6                	ld	a3,104(sp)
ffffffffc0200a7a:	7746                	ld	a4,112(sp)
ffffffffc0200a7c:	77e6                	ld	a5,120(sp)
ffffffffc0200a7e:	680a                	ld	a6,128(sp)
ffffffffc0200a80:	68aa                	ld	a7,136(sp)
ffffffffc0200a82:	694a                	ld	s2,144(sp)
ffffffffc0200a84:	69ea                	ld	s3,152(sp)
ffffffffc0200a86:	7a0a                	ld	s4,160(sp)
ffffffffc0200a88:	7aaa                	ld	s5,168(sp)
ffffffffc0200a8a:	7b4a                	ld	s6,176(sp)
ffffffffc0200a8c:	7bea                	ld	s7,184(sp)
ffffffffc0200a8e:	6c0e                	ld	s8,192(sp)
ffffffffc0200a90:	6cae                	ld	s9,200(sp)
ffffffffc0200a92:	6d4e                	ld	s10,208(sp)
ffffffffc0200a94:	6dee                	ld	s11,216(sp)
ffffffffc0200a96:	7e0e                	ld	t3,224(sp)
ffffffffc0200a98:	7eae                	ld	t4,232(sp)
ffffffffc0200a9a:	7f4e                	ld	t5,240(sp)
ffffffffc0200a9c:	7fee                	ld	t6,248(sp)
ffffffffc0200a9e:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200aa0:	10200073          	sret
	...

ffffffffc0200ab0 <pa2page.part.0>:
*/
static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}
//从物理页面的地址得到所在的物理页面。实际上是得到管理这个物理页面的Page结构体
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200ab0:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200ab2:	00004617          	auipc	a2,0x4
ffffffffc0200ab6:	2a660613          	addi	a2,a2,678 # ffffffffc0204d58 <commands+0x708>
ffffffffc0200aba:	06c00593          	li	a1,108
ffffffffc0200abe:	00004517          	auipc	a0,0x4
ffffffffc0200ac2:	2ba50513          	addi	a0,a0,698 # ffffffffc0204d78 <commands+0x728>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200ac6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200ac8:	e3aff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200acc <pte2page.part.0>:

static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }

static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }

static inline struct Page *pte2page(pte_t pte) {
ffffffffc0200acc:	1141                	addi	sp,sp,-16
    if (!(pte & PTE_V)) {
        panic("pte2page called with invalid pte");
ffffffffc0200ace:	00004617          	auipc	a2,0x4
ffffffffc0200ad2:	2ba60613          	addi	a2,a2,698 # ffffffffc0204d88 <commands+0x738>
ffffffffc0200ad6:	07700593          	li	a1,119
ffffffffc0200ada:	00004517          	auipc	a0,0x4
ffffffffc0200ade:	29e50513          	addi	a0,a0,670 # ffffffffc0204d78 <commands+0x728>
static inline struct Page *pte2page(pte_t pte) {
ffffffffc0200ae2:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200ae4:	e1eff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200ae8 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200ae8:	7139                	addi	sp,sp,-64
ffffffffc0200aea:	f426                	sd	s1,40(sp)
ffffffffc0200aec:	f04a                	sd	s2,32(sp)
ffffffffc0200aee:	ec4e                	sd	s3,24(sp)
ffffffffc0200af0:	e852                	sd	s4,16(sp)
ffffffffc0200af2:	e456                	sd	s5,8(sp)
ffffffffc0200af4:	e05a                	sd	s6,0(sp)
ffffffffc0200af6:	fc06                	sd	ra,56(sp)
ffffffffc0200af8:	f822                	sd	s0,48(sp)
ffffffffc0200afa:	84aa                	mv	s1,a0
ffffffffc0200afc:	00011917          	auipc	s2,0x11
ffffffffc0200b00:	a3490913          	addi	s2,s2,-1484 # ffffffffc0211530 <pmm_manager>
        local_intr_restore(intr_flag);//恢复中断状态

        //如果有足够的物理页面， 就不必换出其他页面
        //如果n>1, 说明希望分配多个连续的页面， 但是我们换出页面的时候并不能换出连续的页面
        //swap_init_ok标志是否成功初始化了
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200b04:	4a05                	li	s4,1
ffffffffc0200b06:	00011a97          	auipc	s5,0x11
ffffffffc0200b0a:	a5aa8a93          	addi	s5,s5,-1446 # ffffffffc0211560 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);//调用页面置换的” 换出页面“ 接口。这里必有n=1
ffffffffc0200b0e:	0005099b          	sext.w	s3,a0
ffffffffc0200b12:	00011b17          	auipc	s6,0x11
ffffffffc0200b16:	a2eb0b13          	addi	s6,s6,-1490 # ffffffffc0211540 <check_mm_struct>
ffffffffc0200b1a:	a01d                	j	ffffffffc0200b40 <alloc_pages+0x58>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0200b1c:	00093783          	ld	a5,0(s2)
ffffffffc0200b20:	6f9c                	ld	a5,24(a5)
ffffffffc0200b22:	9782                	jalr	a5
ffffffffc0200b24:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);//调用页面置换的” 换出页面“ 接口。这里必有n=1
ffffffffc0200b26:	4601                	li	a2,0
ffffffffc0200b28:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200b2a:	ec0d                	bnez	s0,ffffffffc0200b64 <alloc_pages+0x7c>
ffffffffc0200b2c:	029a6c63          	bltu	s4,s1,ffffffffc0200b64 <alloc_pages+0x7c>
ffffffffc0200b30:	000aa783          	lw	a5,0(s5)
ffffffffc0200b34:	2781                	sext.w	a5,a5
ffffffffc0200b36:	c79d                	beqz	a5,ffffffffc0200b64 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);//调用页面置换的” 换出页面“ 接口。这里必有n=1
ffffffffc0200b38:	000b3503          	ld	a0,0(s6)
ffffffffc0200b3c:	20c020ef          	jal	ra,ffffffffc0202d48 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b40:	100027f3          	csrr	a5,sstatus
ffffffffc0200b44:	8b89                	andi	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0200b46:	8526                	mv	a0,s1
ffffffffc0200b48:	dbf1                	beqz	a5,ffffffffc0200b1c <alloc_pages+0x34>
        intr_disable();
ffffffffc0200b4a:	9a5ff0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0200b4e:	00093783          	ld	a5,0(s2)
ffffffffc0200b52:	8526                	mv	a0,s1
ffffffffc0200b54:	6f9c                	ld	a5,24(a5)
ffffffffc0200b56:	9782                	jalr	a5
ffffffffc0200b58:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200b5a:	98fff0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
        swap_out(check_mm_struct, n, 0);//调用页面置换的” 换出页面“ 接口。这里必有n=1
ffffffffc0200b5e:	4601                	li	a2,0
ffffffffc0200b60:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200b62:	d469                	beqz	s0,ffffffffc0200b2c <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200b64:	70e2                	ld	ra,56(sp)
ffffffffc0200b66:	8522                	mv	a0,s0
ffffffffc0200b68:	7442                	ld	s0,48(sp)
ffffffffc0200b6a:	74a2                	ld	s1,40(sp)
ffffffffc0200b6c:	7902                	ld	s2,32(sp)
ffffffffc0200b6e:	69e2                	ld	s3,24(sp)
ffffffffc0200b70:	6a42                	ld	s4,16(sp)
ffffffffc0200b72:	6aa2                	ld	s5,8(sp)
ffffffffc0200b74:	6b02                	ld	s6,0(sp)
ffffffffc0200b76:	6121                	addi	sp,sp,64
ffffffffc0200b78:	8082                	ret

ffffffffc0200b7a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200b7a:	100027f3          	csrr	a5,sstatus
ffffffffc0200b7e:	8b89                	andi	a5,a5,2
ffffffffc0200b80:	e799                	bnez	a5,ffffffffc0200b8e <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;

    local_intr_save(intr_flag);
    { pmm_manager->free_pages(base, n); }
ffffffffc0200b82:	00011797          	auipc	a5,0x11
ffffffffc0200b86:	9ae7b783          	ld	a5,-1618(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200b8a:	739c                	ld	a5,32(a5)
ffffffffc0200b8c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200b8e:	1101                	addi	sp,sp,-32
ffffffffc0200b90:	ec06                	sd	ra,24(sp)
ffffffffc0200b92:	e822                	sd	s0,16(sp)
ffffffffc0200b94:	e426                	sd	s1,8(sp)
ffffffffc0200b96:	842a                	mv	s0,a0
ffffffffc0200b98:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200b9a:	955ff0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0200b9e:	00011797          	auipc	a5,0x11
ffffffffc0200ba2:	9927b783          	ld	a5,-1646(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200ba6:	739c                	ld	a5,32(a5)
ffffffffc0200ba8:	85a6                	mv	a1,s1
ffffffffc0200baa:	8522                	mv	a0,s0
ffffffffc0200bac:	9782                	jalr	a5
    local_intr_restore(intr_flag);
}
ffffffffc0200bae:	6442                	ld	s0,16(sp)
ffffffffc0200bb0:	60e2                	ld	ra,24(sp)
ffffffffc0200bb2:	64a2                	ld	s1,8(sp)
ffffffffc0200bb4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200bb6:	933ff06f          	j	ffffffffc02004e8 <intr_enable>

ffffffffc0200bba <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200bba:	100027f3          	csrr	a5,sstatus
ffffffffc0200bbe:	8b89                	andi	a5,a5,2
ffffffffc0200bc0:	e799                	bnez	a5,ffffffffc0200bce <nr_free_pages+0x14>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0200bc2:	00011797          	auipc	a5,0x11
ffffffffc0200bc6:	96e7b783          	ld	a5,-1682(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200bca:	779c                	ld	a5,40(a5)
ffffffffc0200bcc:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200bce:	1141                	addi	sp,sp,-16
ffffffffc0200bd0:	e406                	sd	ra,8(sp)
ffffffffc0200bd2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200bd4:	91bff0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0200bd8:	00011797          	auipc	a5,0x11
ffffffffc0200bdc:	9587b783          	ld	a5,-1704(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200be0:	779c                	ld	a5,40(a5)
ffffffffc0200be2:	9782                	jalr	a5
ffffffffc0200be4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200be6:	903ff0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200bea:	60a2                	ld	ra,8(sp)
ffffffffc0200bec:	8522                	mv	a0,s0
ffffffffc0200bee:	6402                	ld	s0,0(sp)
ffffffffc0200bf0:	0141                	addi	sp,sp,16
ffffffffc0200bf2:	8082                	ret

ffffffffc0200bf4 <get_pte>:
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];//找到对应的Giga Page
ffffffffc0200bf4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200bf8:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200bfc:	715d                	addi	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];//找到对应的Giga Page
ffffffffc0200bfe:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200c00:	fc26                	sd	s1,56(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];//找到对应的Giga Page
ffffffffc0200c02:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {//如果下一级页表不存在， 那就给它分配一页， 创造新页表
ffffffffc0200c06:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200c08:	f84a                	sd	s2,48(sp)
ffffffffc0200c0a:	f44e                	sd	s3,40(sp)
ffffffffc0200c0c:	f052                	sd	s4,32(sp)
ffffffffc0200c0e:	e486                	sd	ra,72(sp)
ffffffffc0200c10:	e0a2                	sd	s0,64(sp)
ffffffffc0200c12:	ec56                	sd	s5,24(sp)
ffffffffc0200c14:	e85a                	sd	s6,16(sp)
ffffffffc0200c16:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) {//如果下一级页表不存在， 那就给它分配一页， 创造新页表
ffffffffc0200c18:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200c1c:	892e                	mv	s2,a1
ffffffffc0200c1e:	8a32                	mv	s4,a2
ffffffffc0200c20:	00011997          	auipc	s3,0x11
ffffffffc0200c24:	90098993          	addi	s3,s3,-1792 # ffffffffc0211520 <npage>
    if (!(*pdep1 & PTE_V)) {//如果下一级页表不存在， 那就给它分配一页， 创造新页表
ffffffffc0200c28:	efb5                	bnez	a5,ffffffffc0200ca4 <get_pte+0xb0>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200c2a:	14060c63          	beqz	a2,ffffffffc0200d82 <get_pte+0x18e>
ffffffffc0200c2e:	4505                	li	a0,1
ffffffffc0200c30:	eb9ff0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0200c34:	842a                	mv	s0,a0
ffffffffc0200c36:	14050663          	beqz	a0,ffffffffc0200d82 <get_pte+0x18e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c3a:	00011b97          	auipc	s7,0x11
ffffffffc0200c3e:	8eeb8b93          	addi	s7,s7,-1810 # ffffffffc0211528 <pages>
ffffffffc0200c42:	000bb503          	ld	a0,0(s7)
ffffffffc0200c46:	00005b17          	auipc	s6,0x5
ffffffffc0200c4a:	57ab3b03          	ld	s6,1402(s6) # ffffffffc02061c0 <error_string+0x38>
ffffffffc0200c4e:	00080ab7          	lui	s5,0x80
ffffffffc0200c52:	40a40533          	sub	a0,s0,a0
ffffffffc0200c56:	850d                	srai	a0,a0,0x3
ffffffffc0200c58:	03650533          	mul	a0,a0,s6
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200c5c:	00011997          	auipc	s3,0x11
ffffffffc0200c60:	8c498993          	addi	s3,s3,-1852 # ffffffffc0211520 <npage>
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200c64:	4785                	li	a5,1
ffffffffc0200c66:	0009b703          	ld	a4,0(s3)
ffffffffc0200c6a:	c01c                	sw	a5,0(s0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c6c:	9556                	add	a0,a0,s5
ffffffffc0200c6e:	00c51793          	slli	a5,a0,0xc
ffffffffc0200c72:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c74:	0532                	slli	a0,a0,0xc
ffffffffc0200c76:	14e7fd63          	bgeu	a5,a4,ffffffffc0200dd0 <get_pte+0x1dc>
ffffffffc0200c7a:	00011797          	auipc	a5,0x11
ffffffffc0200c7e:	8be7b783          	ld	a5,-1858(a5) # ffffffffc0211538 <va_pa_offset>
ffffffffc0200c82:	6605                	lui	a2,0x1
ffffffffc0200c84:	4581                	li	a1,0
ffffffffc0200c86:	953e                	add	a0,a0,a5
ffffffffc0200c88:	280030ef          	jal	ra,ffffffffc0203f08 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c8c:	000bb683          	ld	a3,0(s7)
ffffffffc0200c90:	40d406b3          	sub	a3,s0,a3
ffffffffc0200c94:	868d                	srai	a3,a3,0x3
ffffffffc0200c96:	036686b3          	mul	a3,a3,s6
ffffffffc0200c9a:	96d6                	add	a3,a3,s5

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200c9c:	06aa                	slli	a3,a3,0xa
ffffffffc0200c9e:	0116e693          	ori	a3,a3,17
        //我们现在在虚拟地址空间中， 所以要转化为KADDR再memset.
        //不管页表怎么构造， 我们确保物理地址和虚拟地址的偏移量始终相同， 那么就可以用这种方式完成对物理内存的访问
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200ca2:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200ca4:	77fd                	lui	a5,0xfffff
ffffffffc0200ca6:	068a                	slli	a3,a3,0x2
ffffffffc0200ca8:	0009b703          	ld	a4,0(s3)
ffffffffc0200cac:	8efd                	and	a3,a3,a5
ffffffffc0200cae:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200cb2:	0ce7fa63          	bgeu	a5,a4,ffffffffc0200d86 <get_pte+0x192>
ffffffffc0200cb6:	00011a97          	auipc	s5,0x11
ffffffffc0200cba:	882a8a93          	addi	s5,s5,-1918 # ffffffffc0211538 <va_pa_offset>
ffffffffc0200cbe:	000ab403          	ld	s0,0(s5)
ffffffffc0200cc2:	01595793          	srli	a5,s2,0x15
ffffffffc0200cc6:	1ff7f793          	andi	a5,a5,511
ffffffffc0200cca:	96a2                	add	a3,a3,s0
ffffffffc0200ccc:	00379413          	slli	s0,a5,0x3
ffffffffc0200cd0:	9436                	add	s0,s0,a3
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc0200cd2:	6014                	ld	a3,0(s0)
ffffffffc0200cd4:	0016f793          	andi	a5,a3,1
ffffffffc0200cd8:	ebad                	bnez	a5,ffffffffc0200d4a <get_pte+0x156>
    	struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200cda:	0a0a0463          	beqz	s4,ffffffffc0200d82 <get_pte+0x18e>
ffffffffc0200cde:	4505                	li	a0,1
ffffffffc0200ce0:	e09ff0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0200ce4:	84aa                	mv	s1,a0
ffffffffc0200ce6:	cd51                	beqz	a0,ffffffffc0200d82 <get_pte+0x18e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ce8:	00011b97          	auipc	s7,0x11
ffffffffc0200cec:	840b8b93          	addi	s7,s7,-1984 # ffffffffc0211528 <pages>
ffffffffc0200cf0:	000bb503          	ld	a0,0(s7)
ffffffffc0200cf4:	00005b17          	auipc	s6,0x5
ffffffffc0200cf8:	4ccb3b03          	ld	s6,1228(s6) # ffffffffc02061c0 <error_string+0x38>
ffffffffc0200cfc:	00080a37          	lui	s4,0x80
ffffffffc0200d00:	40a48533          	sub	a0,s1,a0
ffffffffc0200d04:	850d                	srai	a0,a0,0x3
ffffffffc0200d06:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d0a:	4785                	li	a5,1
        return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200d0c:	0009b703          	ld	a4,0(s3)
ffffffffc0200d10:	c09c                	sw	a5,0(s1)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d12:	9552                	add	a0,a0,s4
ffffffffc0200d14:	00c51793          	slli	a5,a0,0xc
ffffffffc0200d18:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d1a:	0532                	slli	a0,a0,0xc
ffffffffc0200d1c:	08e7fd63          	bgeu	a5,a4,ffffffffc0200db6 <get_pte+0x1c2>
ffffffffc0200d20:	000ab783          	ld	a5,0(s5)
ffffffffc0200d24:	6605                	lui	a2,0x1
ffffffffc0200d26:	4581                	li	a1,0
ffffffffc0200d28:	953e                	add	a0,a0,a5
ffffffffc0200d2a:	1de030ef          	jal	ra,ffffffffc0203f08 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d2e:	000bb683          	ld	a3,0(s7)
ffffffffc0200d32:	40d486b3          	sub	a3,s1,a3
ffffffffc0200d36:	868d                	srai	a3,a3,0x3
ffffffffc0200d38:	036686b3          	mul	a3,a3,s6
ffffffffc0200d3c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d3e:	06aa                	slli	a3,a3,0xa
ffffffffc0200d40:	0116e693          	ori	a3,a3,17
 //   	memset(pa, 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200d44:	e014                	sd	a3,0(s0)
    }
    //找到输入的虚拟地址la对应的页表项的地址(可能是刚刚分配的)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200d46:	0009b703          	ld	a4,0(s3)
ffffffffc0200d4a:	068a                	slli	a3,a3,0x2
ffffffffc0200d4c:	757d                	lui	a0,0xfffff
ffffffffc0200d4e:	8ee9                	and	a3,a3,a0
ffffffffc0200d50:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200d54:	04e7f563          	bgeu	a5,a4,ffffffffc0200d9e <get_pte+0x1aa>
ffffffffc0200d58:	000ab503          	ld	a0,0(s5)
ffffffffc0200d5c:	00c95913          	srli	s2,s2,0xc
ffffffffc0200d60:	1ff97913          	andi	s2,s2,511
ffffffffc0200d64:	96aa                	add	a3,a3,a0
ffffffffc0200d66:	00391513          	slli	a0,s2,0x3
ffffffffc0200d6a:	9536                	add	a0,a0,a3
}
ffffffffc0200d6c:	60a6                	ld	ra,72(sp)
ffffffffc0200d6e:	6406                	ld	s0,64(sp)
ffffffffc0200d70:	74e2                	ld	s1,56(sp)
ffffffffc0200d72:	7942                	ld	s2,48(sp)
ffffffffc0200d74:	79a2                	ld	s3,40(sp)
ffffffffc0200d76:	7a02                	ld	s4,32(sp)
ffffffffc0200d78:	6ae2                	ld	s5,24(sp)
ffffffffc0200d7a:	6b42                	ld	s6,16(sp)
ffffffffc0200d7c:	6ba2                	ld	s7,8(sp)
ffffffffc0200d7e:	6161                	addi	sp,sp,80
ffffffffc0200d80:	8082                	ret
            return NULL;
ffffffffc0200d82:	4501                	li	a0,0
ffffffffc0200d84:	b7e5                	j	ffffffffc0200d6c <get_pte+0x178>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200d86:	00004617          	auipc	a2,0x4
ffffffffc0200d8a:	02a60613          	addi	a2,a2,42 # ffffffffc0204db0 <commands+0x760>
ffffffffc0200d8e:	10800593          	li	a1,264
ffffffffc0200d92:	00004517          	auipc	a0,0x4
ffffffffc0200d96:	04650513          	addi	a0,a0,70 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0200d9a:	b68ff0ef          	jal	ra,ffffffffc0200102 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200d9e:	00004617          	auipc	a2,0x4
ffffffffc0200da2:	01260613          	addi	a2,a2,18 # ffffffffc0204db0 <commands+0x760>
ffffffffc0200da6:	11600593          	li	a1,278
ffffffffc0200daa:	00004517          	auipc	a0,0x4
ffffffffc0200dae:	02e50513          	addi	a0,a0,46 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0200db2:	b50ff0ef          	jal	ra,ffffffffc0200102 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200db6:	86aa                	mv	a3,a0
ffffffffc0200db8:	00004617          	auipc	a2,0x4
ffffffffc0200dbc:	ff860613          	addi	a2,a2,-8 # ffffffffc0204db0 <commands+0x760>
ffffffffc0200dc0:	11100593          	li	a1,273
ffffffffc0200dc4:	00004517          	auipc	a0,0x4
ffffffffc0200dc8:	01450513          	addi	a0,a0,20 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0200dcc:	b36ff0ef          	jal	ra,ffffffffc0200102 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200dd0:	86aa                	mv	a3,a0
ffffffffc0200dd2:	00004617          	auipc	a2,0x4
ffffffffc0200dd6:	fde60613          	addi	a2,a2,-34 # ffffffffc0204db0 <commands+0x760>
ffffffffc0200dda:	10300593          	li	a1,259
ffffffffc0200dde:	00004517          	auipc	a0,0x4
ffffffffc0200de2:	ffa50513          	addi	a0,a0,-6 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0200de6:	b1cff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200dea <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200dea:	1141                	addi	sp,sp,-16
ffffffffc0200dec:	e022                	sd	s0,0(sp)
ffffffffc0200dee:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200df0:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0200df2:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0200df4:	e01ff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0200df8:	c011                	beqz	s0,ffffffffc0200dfc <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0200dfa:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200dfc:	c511                	beqz	a0,ffffffffc0200e08 <get_page+0x1e>
ffffffffc0200dfe:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0200e00:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0200e02:	0017f713          	andi	a4,a5,1
ffffffffc0200e06:	e709                	bnez	a4,ffffffffc0200e10 <get_page+0x26>
}
ffffffffc0200e08:	60a2                	ld	ra,8(sp)
ffffffffc0200e0a:	6402                	ld	s0,0(sp)
ffffffffc0200e0c:	0141                	addi	sp,sp,16
ffffffffc0200e0e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0200e10:	078a                	slli	a5,a5,0x2
ffffffffc0200e12:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200e14:	00010717          	auipc	a4,0x10
ffffffffc0200e18:	70c73703          	ld	a4,1804(a4) # ffffffffc0211520 <npage>
ffffffffc0200e1c:	02e7f263          	bgeu	a5,a4,ffffffffc0200e40 <get_page+0x56>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e20:	fff80537          	lui	a0,0xfff80
ffffffffc0200e24:	97aa                	add	a5,a5,a0
ffffffffc0200e26:	60a2                	ld	ra,8(sp)
ffffffffc0200e28:	6402                	ld	s0,0(sp)
ffffffffc0200e2a:	00379513          	slli	a0,a5,0x3
ffffffffc0200e2e:	97aa                	add	a5,a5,a0
ffffffffc0200e30:	078e                	slli	a5,a5,0x3
ffffffffc0200e32:	00010517          	auipc	a0,0x10
ffffffffc0200e36:	6f653503          	ld	a0,1782(a0) # ffffffffc0211528 <pages>
ffffffffc0200e3a:	953e                	add	a0,a0,a5
ffffffffc0200e3c:	0141                	addi	sp,sp,16
ffffffffc0200e3e:	8082                	ret
ffffffffc0200e40:	c71ff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.0>

ffffffffc0200e44 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200e44:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);//找到页表项所在位置
ffffffffc0200e46:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0200e48:	ec06                	sd	ra,24(sp)
ffffffffc0200e4a:	e822                	sd	s0,16(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);//找到页表项所在位置
ffffffffc0200e4c:	da9ff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
    if (ptep != NULL) {
ffffffffc0200e50:	c511                	beqz	a0,ffffffffc0200e5c <page_remove+0x18>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0200e52:	611c                	ld	a5,0(a0)
ffffffffc0200e54:	842a                	mv	s0,a0
ffffffffc0200e56:	0017f713          	andi	a4,a5,1
ffffffffc0200e5a:	e709                	bnez	a4,ffffffffc0200e64 <page_remove+0x20>
        page_remove_pte(pgdir, la, ptep);//删除这个页表项的映射
    }
}
ffffffffc0200e5c:	60e2                	ld	ra,24(sp)
ffffffffc0200e5e:	6442                	ld	s0,16(sp)
ffffffffc0200e60:	6105                	addi	sp,sp,32
ffffffffc0200e62:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0200e64:	078a                	slli	a5,a5,0x2
ffffffffc0200e66:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200e68:	00010717          	auipc	a4,0x10
ffffffffc0200e6c:	6b873703          	ld	a4,1720(a4) # ffffffffc0211520 <npage>
ffffffffc0200e70:	06e7f563          	bgeu	a5,a4,ffffffffc0200eda <page_remove+0x96>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e74:	fff80737          	lui	a4,0xfff80
ffffffffc0200e78:	97ba                	add	a5,a5,a4
ffffffffc0200e7a:	00379513          	slli	a0,a5,0x3
ffffffffc0200e7e:	97aa                	add	a5,a5,a0
ffffffffc0200e80:	078e                	slli	a5,a5,0x3
ffffffffc0200e82:	00010517          	auipc	a0,0x10
ffffffffc0200e86:	6a653503          	ld	a0,1702(a0) # ffffffffc0211528 <pages>
ffffffffc0200e8a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0200e8c:	411c                	lw	a5,0(a0)
ffffffffc0200e8e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200e92:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0200e94:	cb09                	beqz	a4,ffffffffc0200ea6 <page_remove+0x62>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0200e96:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200e9a:	12000073          	sfence.vma
}
ffffffffc0200e9e:	60e2                	ld	ra,24(sp)
ffffffffc0200ea0:	6442                	ld	s0,16(sp)
ffffffffc0200ea2:	6105                	addi	sp,sp,32
ffffffffc0200ea4:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200ea6:	100027f3          	csrr	a5,sstatus
ffffffffc0200eaa:	8b89                	andi	a5,a5,2
ffffffffc0200eac:	eb89                	bnez	a5,ffffffffc0200ebe <page_remove+0x7a>
    { pmm_manager->free_pages(base, n); }
ffffffffc0200eae:	00010797          	auipc	a5,0x10
ffffffffc0200eb2:	6827b783          	ld	a5,1666(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200eb6:	739c                	ld	a5,32(a5)
ffffffffc0200eb8:	4585                	li	a1,1
ffffffffc0200eba:	9782                	jalr	a5
    if (flag) {
ffffffffc0200ebc:	bfe9                	j	ffffffffc0200e96 <page_remove+0x52>
        intr_disable();
ffffffffc0200ebe:	e42a                	sd	a0,8(sp)
ffffffffc0200ec0:	e2eff0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0200ec4:	00010797          	auipc	a5,0x10
ffffffffc0200ec8:	66c7b783          	ld	a5,1644(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200ecc:	739c                	ld	a5,32(a5)
ffffffffc0200ece:	6522                	ld	a0,8(sp)
ffffffffc0200ed0:	4585                	li	a1,1
ffffffffc0200ed2:	9782                	jalr	a5
        intr_enable();
ffffffffc0200ed4:	e14ff0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0200ed8:	bf7d                	j	ffffffffc0200e96 <page_remove+0x52>
ffffffffc0200eda:	bd7ff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.0>

ffffffffc0200ede <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {//pgdir是页表基址(satp)，page对应物理页面，la是虚拟地址
ffffffffc0200ede:	7179                	addi	sp,sp,-48
ffffffffc0200ee0:	87b2                	mv	a5,a2
ffffffffc0200ee2:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);//获取虚拟地址 la 对应的页表项指针 ptep
ffffffffc0200ee4:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {//pgdir是页表基址(satp)，page对应物理页面，la是虚拟地址
ffffffffc0200ee6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);//获取虚拟地址 la 对应的页表项指针 ptep
ffffffffc0200ee8:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {//pgdir是页表基址(satp)，page对应物理页面，la是虚拟地址
ffffffffc0200eea:	ec26                	sd	s1,24(sp)
ffffffffc0200eec:	f406                	sd	ra,40(sp)
ffffffffc0200eee:	e84a                	sd	s2,16(sp)
ffffffffc0200ef0:	e44e                	sd	s3,8(sp)
ffffffffc0200ef2:	e052                	sd	s4,0(sp)
ffffffffc0200ef4:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);//获取虚拟地址 la 对应的页表项指针 ptep
ffffffffc0200ef6:	cffff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
    if (ptep == NULL) {//先找到对应页表项的位置， 如果原先不存在，get_pte()会分配页表项的内存
ffffffffc0200efa:	cd71                	beqz	a0,ffffffffc0200fd6 <page_insert+0xf8>
    page->ref += 1;
ffffffffc0200efc:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);//指向这个物理页面的虚拟地址增加了一个
    if (*ptep & PTE_V) {//检查页表项是否已经存在有效映射
ffffffffc0200efe:	611c                	ld	a5,0(a0)
ffffffffc0200f00:	89aa                	mv	s3,a0
ffffffffc0200f02:	0016871b          	addiw	a4,a3,1
ffffffffc0200f06:	c018                	sw	a4,0(s0)
ffffffffc0200f08:	0017f713          	andi	a4,a5,1
ffffffffc0200f0c:	e331                	bnez	a4,ffffffffc0200f50 <page_insert+0x72>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f0e:	00010797          	auipc	a5,0x10
ffffffffc0200f12:	61a7b783          	ld	a5,1562(a5) # ffffffffc0211528 <pages>
ffffffffc0200f16:	40f407b3          	sub	a5,s0,a5
ffffffffc0200f1a:	878d                	srai	a5,a5,0x3
ffffffffc0200f1c:	00005417          	auipc	s0,0x5
ffffffffc0200f20:	2a443403          	ld	s0,676(s0) # ffffffffc02061c0 <error_string+0x38>
ffffffffc0200f24:	028787b3          	mul	a5,a5,s0
ffffffffc0200f28:	00080437          	lui	s0,0x80
ffffffffc0200f2c:	97a2                	add	a5,a5,s0
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f2e:	07aa                	slli	a5,a5,0xa
ffffffffc0200f30:	8cdd                	or	s1,s1,a5
ffffffffc0200f32:	0014e493          	ori	s1,s1,1
            page_ref_dec(page);
        } else {//如果原先这个虚拟地址映射到其他物理页面， 那么需要删除映射
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);//构造页表项
ffffffffc0200f36:	0099b023          	sd	s1,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200f3a:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);//页表改变之后要刷新TLB
    return 0;
ffffffffc0200f3e:	4501                	li	a0,0
}
ffffffffc0200f40:	70a2                	ld	ra,40(sp)
ffffffffc0200f42:	7402                	ld	s0,32(sp)
ffffffffc0200f44:	64e2                	ld	s1,24(sp)
ffffffffc0200f46:	6942                	ld	s2,16(sp)
ffffffffc0200f48:	69a2                	ld	s3,8(sp)
ffffffffc0200f4a:	6a02                	ld	s4,0(sp)
ffffffffc0200f4c:	6145                	addi	sp,sp,48
ffffffffc0200f4e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0200f50:	00279713          	slli	a4,a5,0x2
ffffffffc0200f54:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200f56:	00010797          	auipc	a5,0x10
ffffffffc0200f5a:	5ca7b783          	ld	a5,1482(a5) # ffffffffc0211520 <npage>
ffffffffc0200f5e:	06f77e63          	bgeu	a4,a5,ffffffffc0200fda <page_insert+0xfc>
    return &pages[PPN(pa) - nbase];
ffffffffc0200f62:	fff807b7          	lui	a5,0xfff80
ffffffffc0200f66:	973e                	add	a4,a4,a5
ffffffffc0200f68:	00010a17          	auipc	s4,0x10
ffffffffc0200f6c:	5c0a0a13          	addi	s4,s4,1472 # ffffffffc0211528 <pages>
ffffffffc0200f70:	000a3783          	ld	a5,0(s4)
ffffffffc0200f74:	00371913          	slli	s2,a4,0x3
ffffffffc0200f78:	993a                	add	s2,s2,a4
ffffffffc0200f7a:	090e                	slli	s2,s2,0x3
ffffffffc0200f7c:	993e                	add	s2,s2,a5
        if (p == page) {//如果这个映射原先就有
ffffffffc0200f7e:	03240063          	beq	s0,s2,ffffffffc0200f9e <page_insert+0xc0>
    page->ref -= 1;
ffffffffc0200f82:	00092783          	lw	a5,0(s2)
ffffffffc0200f86:	fff7871b          	addiw	a4,a5,-1
ffffffffc0200f8a:	00e92023          	sw	a4,0(s2)
        if (page_ref(page) ==
ffffffffc0200f8e:	cb11                	beqz	a4,ffffffffc0200fa2 <page_insert+0xc4>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0200f90:	0009b023          	sd	zero,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0200f94:	12000073          	sfence.vma
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f98:	000a3783          	ld	a5,0(s4)
}
ffffffffc0200f9c:	bfad                	j	ffffffffc0200f16 <page_insert+0x38>
    page->ref -= 1;
ffffffffc0200f9e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0200fa0:	bf9d                	j	ffffffffc0200f16 <page_insert+0x38>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200fa2:	100027f3          	csrr	a5,sstatus
ffffffffc0200fa6:	8b89                	andi	a5,a5,2
ffffffffc0200fa8:	eb91                	bnez	a5,ffffffffc0200fbc <page_insert+0xde>
    { pmm_manager->free_pages(base, n); }
ffffffffc0200faa:	00010797          	auipc	a5,0x10
ffffffffc0200fae:	5867b783          	ld	a5,1414(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200fb2:	739c                	ld	a5,32(a5)
ffffffffc0200fb4:	4585                	li	a1,1
ffffffffc0200fb6:	854a                	mv	a0,s2
ffffffffc0200fb8:	9782                	jalr	a5
    if (flag) {
ffffffffc0200fba:	bfd9                	j	ffffffffc0200f90 <page_insert+0xb2>
        intr_disable();
ffffffffc0200fbc:	d32ff0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0200fc0:	00010797          	auipc	a5,0x10
ffffffffc0200fc4:	5707b783          	ld	a5,1392(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0200fc8:	739c                	ld	a5,32(a5)
ffffffffc0200fca:	4585                	li	a1,1
ffffffffc0200fcc:	854a                	mv	a0,s2
ffffffffc0200fce:	9782                	jalr	a5
        intr_enable();
ffffffffc0200fd0:	d18ff0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0200fd4:	bf75                	j	ffffffffc0200f90 <page_insert+0xb2>
        return -E_NO_MEM;
ffffffffc0200fd6:	5571                	li	a0,-4
ffffffffc0200fd8:	b7a5                	j	ffffffffc0200f40 <page_insert+0x62>
ffffffffc0200fda:	ad7ff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.0>

ffffffffc0200fde <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0200fde:	00005797          	auipc	a5,0x5
ffffffffc0200fe2:	f0a78793          	addi	a5,a5,-246 # ffffffffc0205ee8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fe6:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0200fe8:	7159                	addi	sp,sp,-112
ffffffffc0200fea:	f45e                	sd	s7,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fec:	00004517          	auipc	a0,0x4
ffffffffc0200ff0:	dfc50513          	addi	a0,a0,-516 # ffffffffc0204de8 <commands+0x798>
    pmm_manager = &default_pmm_manager;
ffffffffc0200ff4:	00010b97          	auipc	s7,0x10
ffffffffc0200ff8:	53cb8b93          	addi	s7,s7,1340 # ffffffffc0211530 <pmm_manager>
void pmm_init(void) {
ffffffffc0200ffc:	f486                	sd	ra,104(sp)
ffffffffc0200ffe:	f0a2                	sd	s0,96(sp)
ffffffffc0201000:	eca6                	sd	s1,88(sp)
ffffffffc0201002:	e8ca                	sd	s2,80(sp)
ffffffffc0201004:	e4ce                	sd	s3,72(sp)
ffffffffc0201006:	f85a                	sd	s6,48(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201008:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc020100c:	e0d2                	sd	s4,64(sp)
ffffffffc020100e:	fc56                	sd	s5,56(sp)
ffffffffc0201010:	f062                	sd	s8,32(sp)
ffffffffc0201012:	ec66                	sd	s9,24(sp)
ffffffffc0201014:	e86a                	sd	s10,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201016:	8a4ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc020101a:	000bb783          	ld	a5,0(s7)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc020101e:	4445                	li	s0,17
ffffffffc0201020:	40100913          	li	s2,1025
    pmm_manager->init();
ffffffffc0201024:	679c                	ld	a5,8(a5)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201026:	00010997          	auipc	s3,0x10
ffffffffc020102a:	51298993          	addi	s3,s3,1298 # ffffffffc0211538 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc020102e:	00010497          	auipc	s1,0x10
ffffffffc0201032:	4f248493          	addi	s1,s1,1266 # ffffffffc0211520 <npage>
    pmm_manager->init();
ffffffffc0201036:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201038:	57f5                	li	a5,-3
ffffffffc020103a:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc020103c:	07e006b7          	lui	a3,0x7e00
ffffffffc0201040:	01b41613          	slli	a2,s0,0x1b
ffffffffc0201044:	01591593          	slli	a1,s2,0x15
ffffffffc0201048:	00004517          	auipc	a0,0x4
ffffffffc020104c:	db850513          	addi	a0,a0,-584 # ffffffffc0204e00 <commands+0x7b0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201050:	00f9b023          	sd	a5,0(s3)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201054:	866ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201058:	00004517          	auipc	a0,0x4
ffffffffc020105c:	dd850513          	addi	a0,a0,-552 # ffffffffc0204e30 <commands+0x7e0>
ffffffffc0201060:	85aff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201064:	01b41693          	slli	a3,s0,0x1b
ffffffffc0201068:	16fd                	addi	a3,a3,-1
ffffffffc020106a:	07e005b7          	lui	a1,0x7e00
ffffffffc020106e:	01591613          	slli	a2,s2,0x15
ffffffffc0201072:	00004517          	auipc	a0,0x4
ffffffffc0201076:	dd650513          	addi	a0,a0,-554 # ffffffffc0204e48 <commands+0x7f8>
ffffffffc020107a:	840ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020107e:	777d                	lui	a4,0xfffff
ffffffffc0201080:	00011797          	auipc	a5,0x11
ffffffffc0201084:	4ef78793          	addi	a5,a5,1263 # ffffffffc021256f <end+0xfff>
ffffffffc0201088:	8ff9                	and	a5,a5,a4
ffffffffc020108a:	00010b17          	auipc	s6,0x10
ffffffffc020108e:	49eb0b13          	addi	s6,s6,1182 # ffffffffc0211528 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201092:	00088737          	lui	a4,0x88
ffffffffc0201096:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201098:	00fb3023          	sd	a5,0(s6)
ffffffffc020109c:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020109e:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010a0:	4505                	li	a0,1
ffffffffc02010a2:	fff805b7          	lui	a1,0xfff80
ffffffffc02010a6:	a019                	j	ffffffffc02010ac <pmm_init+0xce>
        SetPageReserved(pages + i);
ffffffffc02010a8:	000b3783          	ld	a5,0(s6)
ffffffffc02010ac:	97b6                	add	a5,a5,a3
ffffffffc02010ae:	07a1                	addi	a5,a5,8
ffffffffc02010b0:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010b4:	609c                	ld	a5,0(s1)
ffffffffc02010b6:	0705                	addi	a4,a4,1
ffffffffc02010b8:	04868693          	addi	a3,a3,72 # 7e00048 <kern_entry-0xffffffffb83fffb8>
ffffffffc02010bc:	00b78633          	add	a2,a5,a1
ffffffffc02010c0:	fec764e3          	bltu	a4,a2,ffffffffc02010a8 <pmm_init+0xca>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c4:	000b3503          	ld	a0,0(s6)
ffffffffc02010c8:	00379693          	slli	a3,a5,0x3
ffffffffc02010cc:	96be                	add	a3,a3,a5
ffffffffc02010ce:	fdc00737          	lui	a4,0xfdc00
ffffffffc02010d2:	972a                	add	a4,a4,a0
ffffffffc02010d4:	068e                	slli	a3,a3,0x3
ffffffffc02010d6:	96ba                	add	a3,a3,a4
ffffffffc02010d8:	c0200737          	lui	a4,0xc0200
ffffffffc02010dc:	64e6e463          	bltu	a3,a4,ffffffffc0201724 <pmm_init+0x746>
ffffffffc02010e0:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc02010e4:	4645                	li	a2,17
ffffffffc02010e6:	066e                	slli	a2,a2,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e8:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010ea:	4ec6e263          	bltu	a3,a2,ffffffffc02015ce <pmm_init+0x5f0>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010ee:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02010f2:	00010917          	auipc	s2,0x10
ffffffffc02010f6:	42690913          	addi	s2,s2,1062 # ffffffffc0211518 <boot_pgdir>
    pmm_manager->check();
ffffffffc02010fa:	7b9c                	ld	a5,48(a5)
ffffffffc02010fc:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010fe:	00004517          	auipc	a0,0x4
ffffffffc0201102:	d9a50513          	addi	a0,a0,-614 # ffffffffc0204e98 <commands+0x848>
ffffffffc0201106:	fb5fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020110a:	00008697          	auipc	a3,0x8
ffffffffc020110e:	ef668693          	addi	a3,a3,-266 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201112:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201116:	c02007b7          	lui	a5,0xc0200
ffffffffc020111a:	62f6e163          	bltu	a3,a5,ffffffffc020173c <pmm_init+0x75e>
ffffffffc020111e:	0009b783          	ld	a5,0(s3)
ffffffffc0201122:	8e9d                	sub	a3,a3,a5
ffffffffc0201124:	00010797          	auipc	a5,0x10
ffffffffc0201128:	3ed7b623          	sd	a3,1004(a5) # ffffffffc0211510 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020112c:	100027f3          	csrr	a5,sstatus
ffffffffc0201130:	8b89                	andi	a5,a5,2
ffffffffc0201132:	4c079763          	bnez	a5,ffffffffc0201600 <pmm_init+0x622>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201136:	000bb783          	ld	a5,0(s7)
ffffffffc020113a:	779c                	ld	a5,40(a5)
ffffffffc020113c:	9782                	jalr	a5
ffffffffc020113e:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);//检查内核所需的页面数是否小于等于内核顶部地址 KERNTOP 除以页面大小 PGSIZE，以确保内核不会超出其可用的虚拟内存范围
ffffffffc0201140:	6098                	ld	a4,0(s1)
ffffffffc0201142:	c80007b7          	lui	a5,0xc8000
ffffffffc0201146:	83b1                	srli	a5,a5,0xc
ffffffffc0201148:	62e7e663          	bltu	a5,a4,ffffffffc0201774 <pmm_init+0x796>
    //boot_pgdir是页表的虚拟地址
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020114c:	00093503          	ld	a0,0(s2)
ffffffffc0201150:	60050263          	beqz	a0,ffffffffc0201754 <pmm_init+0x776>
ffffffffc0201154:	03451793          	slli	a5,a0,0x34
ffffffffc0201158:	5e079e63          	bnez	a5,ffffffffc0201754 <pmm_init+0x776>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);//检查页目录中虚拟地址0x0是否没有映射到任何页面，确保内核起始地址没有被错误地映射
ffffffffc020115c:	4601                	li	a2,0
ffffffffc020115e:	4581                	li	a1,0
ffffffffc0201160:	c8bff0ef          	jal	ra,ffffffffc0200dea <get_page>
ffffffffc0201164:	66051a63          	bnez	a0,ffffffffc02017d8 <pmm_init+0x7fa>

    struct Page *p1, *p2;
    p1 = alloc_page();//拿过来一个物理页面
ffffffffc0201168:	4505                	li	a0,1
ffffffffc020116a:	97fff0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020116e:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201170:	00093503          	ld	a0,0(s2)
ffffffffc0201174:	4681                	li	a3,0
ffffffffc0201176:	4601                	li	a2,0
ffffffffc0201178:	85d2                	mv	a1,s4
ffffffffc020117a:	d65ff0ef          	jal	ra,ffffffffc0200ede <page_insert>
ffffffffc020117e:	62051d63          	bnez	a0,ffffffffc02017b8 <pmm_init+0x7da>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201182:	00093503          	ld	a0,0(s2)
ffffffffc0201186:	4601                	li	a2,0
ffffffffc0201188:	4581                	li	a1,0
ffffffffc020118a:	a6bff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
ffffffffc020118e:	60050563          	beqz	a0,ffffffffc0201798 <pmm_init+0x7ba>
    assert(pte2page(*ptep) == p1);
ffffffffc0201192:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201194:	0017f713          	andi	a4,a5,1
ffffffffc0201198:	5e070e63          	beqz	a4,ffffffffc0201794 <pmm_init+0x7b6>
    if (PPN(pa) >= npage) {
ffffffffc020119c:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020119e:	078a                	slli	a5,a5,0x2
ffffffffc02011a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02011a2:	56c7ff63          	bgeu	a5,a2,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc02011a6:	fff80737          	lui	a4,0xfff80
ffffffffc02011aa:	97ba                	add	a5,a5,a4
ffffffffc02011ac:	000b3683          	ld	a3,0(s6)
ffffffffc02011b0:	00379713          	slli	a4,a5,0x3
ffffffffc02011b4:	97ba                	add	a5,a5,a4
ffffffffc02011b6:	078e                	slli	a5,a5,0x3
ffffffffc02011b8:	97b6                	add	a5,a5,a3
ffffffffc02011ba:	14fa18e3          	bne	s4,a5,ffffffffc0201b0a <pmm_init+0xb2c>
    assert(page_ref(p1) == 1);
ffffffffc02011be:	000a2703          	lw	a4,0(s4)
ffffffffc02011c2:	4785                	li	a5,1
ffffffffc02011c4:	16f71fe3          	bne	a4,a5,ffffffffc0201b42 <pmm_init+0xb64>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));//获取第一级页表的物理地址，然后将其转换为虚拟地址
ffffffffc02011c8:	00093503          	ld	a0,0(s2)
ffffffffc02011cc:	77fd                	lui	a5,0xfffff
ffffffffc02011ce:	6114                	ld	a3,0(a0)
ffffffffc02011d0:	068a                	slli	a3,a3,0x2
ffffffffc02011d2:	8efd                	and	a3,a3,a5
ffffffffc02011d4:	00c6d713          	srli	a4,a3,0xc
ffffffffc02011d8:	14c779e3          	bgeu	a4,a2,ffffffffc0201b2a <pmm_init+0xb4c>
ffffffffc02011dc:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;//获取第二级页表的虚拟地址
ffffffffc02011e0:	96e2                	add	a3,a3,s8
ffffffffc02011e2:	0006ba83          	ld	s5,0(a3)
ffffffffc02011e6:	0a8a                	slli	s5,s5,0x2
ffffffffc02011e8:	00fafab3          	and	s5,s5,a5
ffffffffc02011ec:	00cad793          	srli	a5,s5,0xc
ffffffffc02011f0:	66c7f463          	bgeu	a5,a2,ffffffffc0201858 <pmm_init+0x87a>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02011f4:	4601                	li	a2,0
ffffffffc02011f6:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;//获取第二级页表的虚拟地址
ffffffffc02011f8:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02011fa:	9fbff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;//获取第二级页表的虚拟地址
ffffffffc02011fe:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201200:	63551c63          	bne	a0,s5,ffffffffc0201838 <pmm_init+0x85a>

    p2 = alloc_page();
ffffffffc0201204:	4505                	li	a0,1
ffffffffc0201206:	8e3ff0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020120a:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020120c:	00093503          	ld	a0,0(s2)
ffffffffc0201210:	46d1                	li	a3,20
ffffffffc0201212:	6605                	lui	a2,0x1
ffffffffc0201214:	85d6                	mv	a1,s5
ffffffffc0201216:	cc9ff0ef          	jal	ra,ffffffffc0200ede <page_insert>
ffffffffc020121a:	5c051f63          	bnez	a0,ffffffffc02017f8 <pmm_init+0x81a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020121e:	00093503          	ld	a0,0(s2)
ffffffffc0201222:	4601                	li	a2,0
ffffffffc0201224:	6585                	lui	a1,0x1
ffffffffc0201226:	9cfff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
ffffffffc020122a:	12050ce3          	beqz	a0,ffffffffc0201b62 <pmm_init+0xb84>
    assert(*ptep & PTE_U);
ffffffffc020122e:	611c                	ld	a5,0(a0)
ffffffffc0201230:	0107f713          	andi	a4,a5,16
ffffffffc0201234:	72070f63          	beqz	a4,ffffffffc0201972 <pmm_init+0x994>
    assert(*ptep & PTE_W);
ffffffffc0201238:	8b91                	andi	a5,a5,4
ffffffffc020123a:	6e078c63          	beqz	a5,ffffffffc0201932 <pmm_init+0x954>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020123e:	00093503          	ld	a0,0(s2)
ffffffffc0201242:	611c                	ld	a5,0(a0)
ffffffffc0201244:	8bc1                	andi	a5,a5,16
ffffffffc0201246:	6c078663          	beqz	a5,ffffffffc0201912 <pmm_init+0x934>
    assert(page_ref(p2) == 1);
ffffffffc020124a:	000aa703          	lw	a4,0(s5)
ffffffffc020124e:	4785                	li	a5,1
ffffffffc0201250:	5cf71463          	bne	a4,a5,ffffffffc0201818 <pmm_init+0x83a>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201254:	4681                	li	a3,0
ffffffffc0201256:	6605                	lui	a2,0x1
ffffffffc0201258:	85d2                	mv	a1,s4
ffffffffc020125a:	c85ff0ef          	jal	ra,ffffffffc0200ede <page_insert>
ffffffffc020125e:	66051a63          	bnez	a0,ffffffffc02018d2 <pmm_init+0x8f4>
    assert(page_ref(p1) == 2);
ffffffffc0201262:	000a2703          	lw	a4,0(s4)
ffffffffc0201266:	4789                	li	a5,2
ffffffffc0201268:	64f71563          	bne	a4,a5,ffffffffc02018b2 <pmm_init+0x8d4>
    assert(page_ref(p2) == 0);
ffffffffc020126c:	000aa783          	lw	a5,0(s5)
ffffffffc0201270:	62079163          	bnez	a5,ffffffffc0201892 <pmm_init+0x8b4>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201274:	00093503          	ld	a0,0(s2)
ffffffffc0201278:	4601                	li	a2,0
ffffffffc020127a:	6585                	lui	a1,0x1
ffffffffc020127c:	979ff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
ffffffffc0201280:	5e050963          	beqz	a0,ffffffffc0201872 <pmm_init+0x894>
    assert(pte2page(*ptep) == p1);
ffffffffc0201284:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201286:	00177793          	andi	a5,a4,1
ffffffffc020128a:	50078563          	beqz	a5,ffffffffc0201794 <pmm_init+0x7b6>
    if (PPN(pa) >= npage) {
ffffffffc020128e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201290:	00271793          	slli	a5,a4,0x2
ffffffffc0201294:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201296:	48d7f563          	bgeu	a5,a3,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc020129a:	fff806b7          	lui	a3,0xfff80
ffffffffc020129e:	97b6                	add	a5,a5,a3
ffffffffc02012a0:	000b3603          	ld	a2,0(s6)
ffffffffc02012a4:	00379693          	slli	a3,a5,0x3
ffffffffc02012a8:	97b6                	add	a5,a5,a3
ffffffffc02012aa:	078e                	slli	a5,a5,0x3
ffffffffc02012ac:	97b2                	add	a5,a5,a2
ffffffffc02012ae:	72fa1263          	bne	s4,a5,ffffffffc02019d2 <pmm_init+0x9f4>
    assert((*ptep & PTE_U) == 0);
ffffffffc02012b2:	8b41                	andi	a4,a4,16
ffffffffc02012b4:	6e071f63          	bnez	a4,ffffffffc02019b2 <pmm_init+0x9d4>

    page_remove(boot_pgdir, 0x0);
ffffffffc02012b8:	00093503          	ld	a0,0(s2)
ffffffffc02012bc:	4581                	li	a1,0
ffffffffc02012be:	b87ff0ef          	jal	ra,ffffffffc0200e44 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02012c2:	000a2703          	lw	a4,0(s4)
ffffffffc02012c6:	4785                	li	a5,1
ffffffffc02012c8:	6cf71563          	bne	a4,a5,ffffffffc0201992 <pmm_init+0x9b4>
    assert(page_ref(p2) == 0);
ffffffffc02012cc:	000aa783          	lw	a5,0(s5)
ffffffffc02012d0:	78079d63          	bnez	a5,ffffffffc0201a6a <pmm_init+0xa8c>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc02012d4:	00093503          	ld	a0,0(s2)
ffffffffc02012d8:	6585                	lui	a1,0x1
ffffffffc02012da:	b6bff0ef          	jal	ra,ffffffffc0200e44 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02012de:	000a2783          	lw	a5,0(s4)
ffffffffc02012e2:	76079463          	bnez	a5,ffffffffc0201a4a <pmm_init+0xa6c>
    assert(page_ref(p2) == 0);
ffffffffc02012e6:	000aa783          	lw	a5,0(s5)
ffffffffc02012ea:	74079063          	bnez	a5,ffffffffc0201a2a <pmm_init+0xa4c>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);//检查页目录的引用计数是否为1，确保页目录不会被错误地释放
ffffffffc02012ee:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02012f2:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02012f4:	000a3783          	ld	a5,0(s4)
ffffffffc02012f8:	078a                	slli	a5,a5,0x2
ffffffffc02012fa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02012fc:	42c7f263          	bgeu	a5,a2,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc0201300:	fff80737          	lui	a4,0xfff80
ffffffffc0201304:	973e                	add	a4,a4,a5
ffffffffc0201306:	00371793          	slli	a5,a4,0x3
ffffffffc020130a:	000b3503          	ld	a0,0(s6)
ffffffffc020130e:	97ba                	add	a5,a5,a4
ffffffffc0201310:	078e                	slli	a5,a5,0x3
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc0201312:	00f50733          	add	a4,a0,a5
ffffffffc0201316:	4314                	lw	a3,0(a4)
ffffffffc0201318:	4705                	li	a4,1
ffffffffc020131a:	6ee69863          	bne	a3,a4,ffffffffc0201a0a <pmm_init+0xa2c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020131e:	4037d693          	srai	a3,a5,0x3
ffffffffc0201322:	00005c97          	auipc	s9,0x5
ffffffffc0201326:	e9ecbc83          	ld	s9,-354(s9) # ffffffffc02061c0 <error_string+0x38>
ffffffffc020132a:	039686b3          	mul	a3,a3,s9
ffffffffc020132e:	000805b7          	lui	a1,0x80
ffffffffc0201332:	96ae                	add	a3,a3,a1
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201334:	00c69713          	slli	a4,a3,0xc
ffffffffc0201338:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020133a:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020133c:	6ac77b63          	bgeu	a4,a2,ffffffffc02019f2 <pmm_init+0xa14>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201340:	0009b703          	ld	a4,0(s3)
ffffffffc0201344:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0201346:	629c                	ld	a5,0(a3)
ffffffffc0201348:	078a                	slli	a5,a5,0x2
ffffffffc020134a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020134c:	3cc7fa63          	bgeu	a5,a2,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc0201350:	8f8d                	sub	a5,a5,a1
ffffffffc0201352:	00379713          	slli	a4,a5,0x3
ffffffffc0201356:	97ba                	add	a5,a5,a4
ffffffffc0201358:	078e                	slli	a5,a5,0x3
ffffffffc020135a:	953e                	add	a0,a0,a5
ffffffffc020135c:	100027f3          	csrr	a5,sstatus
ffffffffc0201360:	8b89                	andi	a5,a5,2
ffffffffc0201362:	2e079963          	bnez	a5,ffffffffc0201654 <pmm_init+0x676>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201366:	000bb783          	ld	a5,0(s7)
ffffffffc020136a:	4585                	li	a1,1
ffffffffc020136c:	739c                	ld	a5,32(a5)
ffffffffc020136e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201370:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201374:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201376:	078a                	slli	a5,a5,0x2
ffffffffc0201378:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020137a:	3ae7f363          	bgeu	a5,a4,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc020137e:	fff80737          	lui	a4,0xfff80
ffffffffc0201382:	97ba                	add	a5,a5,a4
ffffffffc0201384:	000b3503          	ld	a0,0(s6)
ffffffffc0201388:	00379713          	slli	a4,a5,0x3
ffffffffc020138c:	97ba                	add	a5,a5,a4
ffffffffc020138e:	078e                	slli	a5,a5,0x3
ffffffffc0201390:	953e                	add	a0,a0,a5
ffffffffc0201392:	100027f3          	csrr	a5,sstatus
ffffffffc0201396:	8b89                	andi	a5,a5,2
ffffffffc0201398:	2a079263          	bnez	a5,ffffffffc020163c <pmm_init+0x65e>
ffffffffc020139c:	000bb783          	ld	a5,0(s7)
ffffffffc02013a0:	4585                	li	a1,1
ffffffffc02013a2:	739c                	ld	a5,32(a5)
ffffffffc02013a4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02013a6:	00093783          	ld	a5,0(s2)
ffffffffc02013aa:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdeda90>
ffffffffc02013ae:	100027f3          	csrr	a5,sstatus
ffffffffc02013b2:	8b89                	andi	a5,a5,2
ffffffffc02013b4:	26079a63          	bnez	a5,ffffffffc0201628 <pmm_init+0x64a>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02013b8:	000bb783          	ld	a5,0(s7)
ffffffffc02013bc:	779c                	ld	a5,40(a5)
ffffffffc02013be:	9782                	jalr	a5
ffffffffc02013c0:	8a2a                	mv	s4,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc02013c2:	73441463          	bne	s0,s4,ffffffffc0201aea <pmm_init+0xb0c>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02013c6:	00004517          	auipc	a0,0x4
ffffffffc02013ca:	dd250513          	addi	a0,a0,-558 # ffffffffc0205198 <commands+0xb48>
ffffffffc02013ce:	cedfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02013d2:	100027f3          	csrr	a5,sstatus
ffffffffc02013d6:	8b89                	andi	a5,a5,2
ffffffffc02013d8:	22079e63          	bnez	a5,ffffffffc0201614 <pmm_init+0x636>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02013dc:	000bb783          	ld	a5,0(s7)
ffffffffc02013e0:	779c                	ld	a5,40(a5)
ffffffffc02013e2:	9782                	jalr	a5
ffffffffc02013e4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013e6:	6098                	ld	a4,0(s1)
ffffffffc02013e8:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02013ec:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02013ee:	00c71793          	slli	a5,a4,0xc
ffffffffc02013f2:	6a05                	lui	s4,0x1
ffffffffc02013f4:	02f47c63          	bgeu	s0,a5,ffffffffc020142c <pmm_init+0x44e>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02013f8:	00c45793          	srli	a5,s0,0xc
ffffffffc02013fc:	00093503          	ld	a0,0(s2)
ffffffffc0201400:	30e7f363          	bgeu	a5,a4,ffffffffc0201706 <pmm_init+0x728>
ffffffffc0201404:	0009b583          	ld	a1,0(s3)
ffffffffc0201408:	4601                	li	a2,0
ffffffffc020140a:	95a2                	add	a1,a1,s0
ffffffffc020140c:	fe8ff0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
ffffffffc0201410:	2c050b63          	beqz	a0,ffffffffc02016e6 <pmm_init+0x708>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201414:	611c                	ld	a5,0(a0)
ffffffffc0201416:	078a                	slli	a5,a5,0x2
ffffffffc0201418:	0157f7b3          	and	a5,a5,s5
ffffffffc020141c:	2a879563          	bne	a5,s0,ffffffffc02016c6 <pmm_init+0x6e8>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201420:	6098                	ld	a4,0(s1)
ffffffffc0201422:	9452                	add	s0,s0,s4
ffffffffc0201424:	00c71793          	slli	a5,a4,0xc
ffffffffc0201428:	fcf468e3          	bltu	s0,a5,ffffffffc02013f8 <pmm_init+0x41a>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc020142c:	00093783          	ld	a5,0(s2)
ffffffffc0201430:	639c                	ld	a5,0(a5)
ffffffffc0201432:	68079c63          	bnez	a5,ffffffffc0201aca <pmm_init+0xaec>

    struct Page *p;
    p = alloc_page();
ffffffffc0201436:	4505                	li	a0,1
ffffffffc0201438:	eb0ff0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020143c:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020143e:	00093503          	ld	a0,0(s2)
ffffffffc0201442:	4699                	li	a3,6
ffffffffc0201444:	10000613          	li	a2,256
ffffffffc0201448:	85d6                	mv	a1,s5
ffffffffc020144a:	a95ff0ef          	jal	ra,ffffffffc0200ede <page_insert>
ffffffffc020144e:	64051e63          	bnez	a0,ffffffffc0201aaa <pmm_init+0xacc>
    assert(page_ref(p) == 1);
ffffffffc0201452:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fdeda90>
ffffffffc0201456:	4785                	li	a5,1
ffffffffc0201458:	62f71963          	bne	a4,a5,ffffffffc0201a8a <pmm_init+0xaac>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020145c:	00093503          	ld	a0,0(s2)
ffffffffc0201460:	6405                	lui	s0,0x1
ffffffffc0201462:	4699                	li	a3,6
ffffffffc0201464:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201468:	85d6                	mv	a1,s5
ffffffffc020146a:	a75ff0ef          	jal	ra,ffffffffc0200ede <page_insert>
ffffffffc020146e:	48051263          	bnez	a0,ffffffffc02018f2 <pmm_init+0x914>
    assert(page_ref(p) == 2);
ffffffffc0201472:	000aa703          	lw	a4,0(s5)
ffffffffc0201476:	4789                	li	a5,2
ffffffffc0201478:	74f71563          	bne	a4,a5,ffffffffc0201bc2 <pmm_init+0xbe4>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020147c:	00004597          	auipc	a1,0x4
ffffffffc0201480:	e5458593          	addi	a1,a1,-428 # ffffffffc02052d0 <commands+0xc80>
ffffffffc0201484:	10000513          	li	a0,256
ffffffffc0201488:	23b020ef          	jal	ra,ffffffffc0203ec2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020148c:	10040593          	addi	a1,s0,256
ffffffffc0201490:	10000513          	li	a0,256
ffffffffc0201494:	241020ef          	jal	ra,ffffffffc0203ed4 <strcmp>
ffffffffc0201498:	70051563          	bnez	a0,ffffffffc0201ba2 <pmm_init+0xbc4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020149c:	000b3683          	ld	a3,0(s6)
ffffffffc02014a0:	00080d37          	lui	s10,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02014a4:	547d                	li	s0,-1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02014a6:	40da86b3          	sub	a3,s5,a3
ffffffffc02014aa:	868d                	srai	a3,a3,0x3
ffffffffc02014ac:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02014b0:	609c                	ld	a5,0(s1)
ffffffffc02014b2:	8031                	srli	s0,s0,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02014b4:	96ea                	add	a3,a3,s10
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02014b6:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02014ba:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02014bc:	52f77b63          	bgeu	a4,a5,ffffffffc02019f2 <pmm_init+0xa14>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02014c0:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02014c4:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02014c8:	96be                	add	a3,a3,a5
ffffffffc02014ca:	10068023          	sb	zero,256(a3) # fffffffffff80100 <end+0x3fd6eb90>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02014ce:	1bf020ef          	jal	ra,ffffffffc0203e8c <strlen>
ffffffffc02014d2:	6a051863          	bnez	a0,ffffffffc0201b82 <pmm_init+0xba4>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02014d6:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02014da:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02014dc:	000a3783          	ld	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02014e0:	078a                	slli	a5,a5,0x2
ffffffffc02014e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02014e4:	22e7fe63          	bgeu	a5,a4,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc02014e8:	41a787b3          	sub	a5,a5,s10
ffffffffc02014ec:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02014f0:	96be                	add	a3,a3,a5
ffffffffc02014f2:	03968cb3          	mul	s9,a3,s9
ffffffffc02014f6:	01ac86b3          	add	a3,s9,s10
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02014fa:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02014fc:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02014fe:	4ee47a63          	bgeu	s0,a4,ffffffffc02019f2 <pmm_init+0xa14>
ffffffffc0201502:	0009b403          	ld	s0,0(s3)
ffffffffc0201506:	9436                	add	s0,s0,a3
ffffffffc0201508:	100027f3          	csrr	a5,sstatus
ffffffffc020150c:	8b89                	andi	a5,a5,2
ffffffffc020150e:	1a079163          	bnez	a5,ffffffffc02016b0 <pmm_init+0x6d2>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201512:	000bb783          	ld	a5,0(s7)
ffffffffc0201516:	4585                	li	a1,1
ffffffffc0201518:	8556                	mv	a0,s5
ffffffffc020151a:	739c                	ld	a5,32(a5)
ffffffffc020151c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020151e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201520:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201522:	078a                	slli	a5,a5,0x2
ffffffffc0201524:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201526:	1ee7fd63          	bgeu	a5,a4,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc020152a:	fff80737          	lui	a4,0xfff80
ffffffffc020152e:	97ba                	add	a5,a5,a4
ffffffffc0201530:	000b3503          	ld	a0,0(s6)
ffffffffc0201534:	00379713          	slli	a4,a5,0x3
ffffffffc0201538:	97ba                	add	a5,a5,a4
ffffffffc020153a:	078e                	slli	a5,a5,0x3
ffffffffc020153c:	953e                	add	a0,a0,a5
ffffffffc020153e:	100027f3          	csrr	a5,sstatus
ffffffffc0201542:	8b89                	andi	a5,a5,2
ffffffffc0201544:	14079a63          	bnez	a5,ffffffffc0201698 <pmm_init+0x6ba>
ffffffffc0201548:	000bb783          	ld	a5,0(s7)
ffffffffc020154c:	4585                	li	a1,1
ffffffffc020154e:	739c                	ld	a5,32(a5)
ffffffffc0201550:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201552:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201556:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201558:	078a                	slli	a5,a5,0x2
ffffffffc020155a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020155c:	1ce7f263          	bgeu	a5,a4,ffffffffc0201720 <pmm_init+0x742>
    return &pages[PPN(pa) - nbase];
ffffffffc0201560:	fff80737          	lui	a4,0xfff80
ffffffffc0201564:	97ba                	add	a5,a5,a4
ffffffffc0201566:	000b3503          	ld	a0,0(s6)
ffffffffc020156a:	00379713          	slli	a4,a5,0x3
ffffffffc020156e:	97ba                	add	a5,a5,a4
ffffffffc0201570:	078e                	slli	a5,a5,0x3
ffffffffc0201572:	953e                	add	a0,a0,a5
ffffffffc0201574:	100027f3          	csrr	a5,sstatus
ffffffffc0201578:	8b89                	andi	a5,a5,2
ffffffffc020157a:	10079363          	bnez	a5,ffffffffc0201680 <pmm_init+0x6a2>
ffffffffc020157e:	000bb783          	ld	a5,0(s7)
ffffffffc0201582:	4585                	li	a1,1
ffffffffc0201584:	739c                	ld	a5,32(a5)
ffffffffc0201586:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201588:	00093783          	ld	a5,0(s2)
ffffffffc020158c:	0007b023          	sd	zero,0(a5)
ffffffffc0201590:	100027f3          	csrr	a5,sstatus
ffffffffc0201594:	8b89                	andi	a5,a5,2
ffffffffc0201596:	0c079b63          	bnez	a5,ffffffffc020166c <pmm_init+0x68e>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020159a:	000bb783          	ld	a5,0(s7)
ffffffffc020159e:	779c                	ld	a5,40(a5)
ffffffffc02015a0:	9782                	jalr	a5
ffffffffc02015a2:	842a                	mv	s0,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc02015a4:	3a8c1763          	bne	s8,s0,ffffffffc0201952 <pmm_init+0x974>
}
ffffffffc02015a8:	7406                	ld	s0,96(sp)
ffffffffc02015aa:	70a6                	ld	ra,104(sp)
ffffffffc02015ac:	64e6                	ld	s1,88(sp)
ffffffffc02015ae:	6946                	ld	s2,80(sp)
ffffffffc02015b0:	69a6                	ld	s3,72(sp)
ffffffffc02015b2:	6a06                	ld	s4,64(sp)
ffffffffc02015b4:	7ae2                	ld	s5,56(sp)
ffffffffc02015b6:	7b42                	ld	s6,48(sp)
ffffffffc02015b8:	7ba2                	ld	s7,40(sp)
ffffffffc02015ba:	7c02                	ld	s8,32(sp)
ffffffffc02015bc:	6ce2                	ld	s9,24(sp)
ffffffffc02015be:	6d42                	ld	s10,16(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02015c0:	00004517          	auipc	a0,0x4
ffffffffc02015c4:	d8850513          	addi	a0,a0,-632 # ffffffffc0205348 <commands+0xcf8>
}
ffffffffc02015c8:	6165                	addi	sp,sp,112
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02015ca:	af1fe06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02015ce:	6705                	lui	a4,0x1
ffffffffc02015d0:	177d                	addi	a4,a4,-1
ffffffffc02015d2:	96ba                	add	a3,a3,a4
ffffffffc02015d4:	777d                	lui	a4,0xfffff
ffffffffc02015d6:	8f75                	and	a4,a4,a3
    if (PPN(pa) >= npage) {
ffffffffc02015d8:	00c75693          	srli	a3,a4,0xc
ffffffffc02015dc:	14f6f263          	bgeu	a3,a5,ffffffffc0201720 <pmm_init+0x742>
    pmm_manager->init_memmap(base, n);
ffffffffc02015e0:	000bb803          	ld	a6,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc02015e4:	95b6                	add	a1,a1,a3
ffffffffc02015e6:	00359793          	slli	a5,a1,0x3
ffffffffc02015ea:	97ae                	add	a5,a5,a1
ffffffffc02015ec:	01083683          	ld	a3,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02015f0:	40e60733          	sub	a4,a2,a4
ffffffffc02015f4:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02015f6:	00c75593          	srli	a1,a4,0xc
ffffffffc02015fa:	953e                	add	a0,a0,a5
ffffffffc02015fc:	9682                	jalr	a3
}
ffffffffc02015fe:	bcc5                	j	ffffffffc02010ee <pmm_init+0x110>
        intr_disable();
ffffffffc0201600:	eeffe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201604:	000bb783          	ld	a5,0(s7)
ffffffffc0201608:	779c                	ld	a5,40(a5)
ffffffffc020160a:	9782                	jalr	a5
ffffffffc020160c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020160e:	edbfe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0201612:	b63d                	j	ffffffffc0201140 <pmm_init+0x162>
        intr_disable();
ffffffffc0201614:	edbfe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0201618:	000bb783          	ld	a5,0(s7)
ffffffffc020161c:	779c                	ld	a5,40(a5)
ffffffffc020161e:	9782                	jalr	a5
ffffffffc0201620:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201622:	ec7fe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0201626:	b3c1                	j	ffffffffc02013e6 <pmm_init+0x408>
        intr_disable();
ffffffffc0201628:	ec7fe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc020162c:	000bb783          	ld	a5,0(s7)
ffffffffc0201630:	779c                	ld	a5,40(a5)
ffffffffc0201632:	9782                	jalr	a5
ffffffffc0201634:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201636:	eb3fe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc020163a:	b361                	j	ffffffffc02013c2 <pmm_init+0x3e4>
ffffffffc020163c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020163e:	eb1fe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201642:	000bb783          	ld	a5,0(s7)
ffffffffc0201646:	6522                	ld	a0,8(sp)
ffffffffc0201648:	4585                	li	a1,1
ffffffffc020164a:	739c                	ld	a5,32(a5)
ffffffffc020164c:	9782                	jalr	a5
        intr_enable();
ffffffffc020164e:	e9bfe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0201652:	bb91                	j	ffffffffc02013a6 <pmm_init+0x3c8>
ffffffffc0201654:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201656:	e99fe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc020165a:	000bb783          	ld	a5,0(s7)
ffffffffc020165e:	6522                	ld	a0,8(sp)
ffffffffc0201660:	4585                	li	a1,1
ffffffffc0201662:	739c                	ld	a5,32(a5)
ffffffffc0201664:	9782                	jalr	a5
        intr_enable();
ffffffffc0201666:	e83fe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc020166a:	b319                	j	ffffffffc0201370 <pmm_init+0x392>
        intr_disable();
ffffffffc020166c:	e83fe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201670:	000bb783          	ld	a5,0(s7)
ffffffffc0201674:	779c                	ld	a5,40(a5)
ffffffffc0201676:	9782                	jalr	a5
ffffffffc0201678:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020167a:	e6ffe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc020167e:	b71d                	j	ffffffffc02015a4 <pmm_init+0x5c6>
ffffffffc0201680:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201682:	e6dfe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201686:	000bb783          	ld	a5,0(s7)
ffffffffc020168a:	6522                	ld	a0,8(sp)
ffffffffc020168c:	4585                	li	a1,1
ffffffffc020168e:	739c                	ld	a5,32(a5)
ffffffffc0201690:	9782                	jalr	a5
        intr_enable();
ffffffffc0201692:	e57fe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0201696:	bdcd                	j	ffffffffc0201588 <pmm_init+0x5aa>
ffffffffc0201698:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020169a:	e55fe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc020169e:	000bb783          	ld	a5,0(s7)
ffffffffc02016a2:	6522                	ld	a0,8(sp)
ffffffffc02016a4:	4585                	li	a1,1
ffffffffc02016a6:	739c                	ld	a5,32(a5)
ffffffffc02016a8:	9782                	jalr	a5
        intr_enable();
ffffffffc02016aa:	e3ffe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02016ae:	b555                	j	ffffffffc0201552 <pmm_init+0x574>
        intr_disable();
ffffffffc02016b0:	e3ffe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02016b4:	000bb783          	ld	a5,0(s7)
ffffffffc02016b8:	4585                	li	a1,1
ffffffffc02016ba:	8556                	mv	a0,s5
ffffffffc02016bc:	739c                	ld	a5,32(a5)
ffffffffc02016be:	9782                	jalr	a5
        intr_enable();
ffffffffc02016c0:	e29fe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02016c4:	bda9                	j	ffffffffc020151e <pmm_init+0x540>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016c6:	00004697          	auipc	a3,0x4
ffffffffc02016ca:	b3268693          	addi	a3,a3,-1230 # ffffffffc02051f8 <commands+0xba8>
ffffffffc02016ce:	00004617          	auipc	a2,0x4
ffffffffc02016d2:	80a60613          	addi	a2,a2,-2038 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02016d6:	1d600593          	li	a1,470
ffffffffc02016da:	00003517          	auipc	a0,0x3
ffffffffc02016de:	6fe50513          	addi	a0,a0,1790 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02016e2:	a21fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02016e6:	00004697          	auipc	a3,0x4
ffffffffc02016ea:	ad268693          	addi	a3,a3,-1326 # ffffffffc02051b8 <commands+0xb68>
ffffffffc02016ee:	00003617          	auipc	a2,0x3
ffffffffc02016f2:	7ea60613          	addi	a2,a2,2026 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02016f6:	1d500593          	li	a1,469
ffffffffc02016fa:	00003517          	auipc	a0,0x3
ffffffffc02016fe:	6de50513          	addi	a0,a0,1758 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201702:	a01fe0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0201706:	86a2                	mv	a3,s0
ffffffffc0201708:	00003617          	auipc	a2,0x3
ffffffffc020170c:	6a860613          	addi	a2,a2,1704 # ffffffffc0204db0 <commands+0x760>
ffffffffc0201710:	1d500593          	li	a1,469
ffffffffc0201714:	00003517          	auipc	a0,0x3
ffffffffc0201718:	6c450513          	addi	a0,a0,1732 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020171c:	9e7fe0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0201720:	b90ff0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201724:	00003617          	auipc	a2,0x3
ffffffffc0201728:	74c60613          	addi	a2,a2,1868 # ffffffffc0204e70 <commands+0x820>
ffffffffc020172c:	07a00593          	li	a1,122
ffffffffc0201730:	00003517          	auipc	a0,0x3
ffffffffc0201734:	6a850513          	addi	a0,a0,1704 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201738:	9cbfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020173c:	00003617          	auipc	a2,0x3
ffffffffc0201740:	73460613          	addi	a2,a2,1844 # ffffffffc0204e70 <commands+0x820>
ffffffffc0201744:	0c000593          	li	a1,192
ffffffffc0201748:	00003517          	auipc	a0,0x3
ffffffffc020174c:	69050513          	addi	a0,a0,1680 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201750:	9b3fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201754:	00003697          	auipc	a3,0x3
ffffffffc0201758:	79c68693          	addi	a3,a3,1948 # ffffffffc0204ef0 <commands+0x8a0>
ffffffffc020175c:	00003617          	auipc	a2,0x3
ffffffffc0201760:	77c60613          	addi	a2,a2,1916 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201764:	19b00593          	li	a1,411
ffffffffc0201768:	00003517          	auipc	a0,0x3
ffffffffc020176c:	67050513          	addi	a0,a0,1648 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201770:	993fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(npage <= KERNTOP / PGSIZE);//检查内核所需的页面数是否小于等于内核顶部地址 KERNTOP 除以页面大小 PGSIZE，以确保内核不会超出其可用的虚拟内存范围
ffffffffc0201774:	00003697          	auipc	a3,0x3
ffffffffc0201778:	74468693          	addi	a3,a3,1860 # ffffffffc0204eb8 <commands+0x868>
ffffffffc020177c:	00003617          	auipc	a2,0x3
ffffffffc0201780:	75c60613          	addi	a2,a2,1884 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201784:	19900593          	li	a1,409
ffffffffc0201788:	00003517          	auipc	a0,0x3
ffffffffc020178c:	65050513          	addi	a0,a0,1616 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201790:	973fe0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0201794:	b38ff0ef          	jal	ra,ffffffffc0200acc <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201798:	00003697          	auipc	a3,0x3
ffffffffc020179c:	7e868693          	addi	a3,a3,2024 # ffffffffc0204f80 <commands+0x930>
ffffffffc02017a0:	00003617          	auipc	a2,0x3
ffffffffc02017a4:	73860613          	addi	a2,a2,1848 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02017a8:	1a200593          	li	a1,418
ffffffffc02017ac:	00003517          	auipc	a0,0x3
ffffffffc02017b0:	62c50513          	addi	a0,a0,1580 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02017b4:	94ffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02017b8:	00003697          	auipc	a3,0x3
ffffffffc02017bc:	79868693          	addi	a3,a3,1944 # ffffffffc0204f50 <commands+0x900>
ffffffffc02017c0:	00003617          	auipc	a2,0x3
ffffffffc02017c4:	71860613          	addi	a2,a2,1816 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02017c8:	1a000593          	li	a1,416
ffffffffc02017cc:	00003517          	auipc	a0,0x3
ffffffffc02017d0:	60c50513          	addi	a0,a0,1548 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02017d4:	92ffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);//检查页目录中虚拟地址0x0是否没有映射到任何页面，确保内核起始地址没有被错误地映射
ffffffffc02017d8:	00003697          	auipc	a3,0x3
ffffffffc02017dc:	75068693          	addi	a3,a3,1872 # ffffffffc0204f28 <commands+0x8d8>
ffffffffc02017e0:	00003617          	auipc	a2,0x3
ffffffffc02017e4:	6f860613          	addi	a2,a2,1784 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02017e8:	19c00593          	li	a1,412
ffffffffc02017ec:	00003517          	auipc	a0,0x3
ffffffffc02017f0:	5ec50513          	addi	a0,a0,1516 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02017f4:	90ffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02017f8:	00004697          	auipc	a3,0x4
ffffffffc02017fc:	81068693          	addi	a3,a3,-2032 # ffffffffc0205008 <commands+0x9b8>
ffffffffc0201800:	00003617          	auipc	a2,0x3
ffffffffc0201804:	6d860613          	addi	a2,a2,1752 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201808:	1ab00593          	li	a1,427
ffffffffc020180c:	00003517          	auipc	a0,0x3
ffffffffc0201810:	5cc50513          	addi	a0,a0,1484 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201814:	8effe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201818:	00004697          	auipc	a3,0x4
ffffffffc020181c:	89068693          	addi	a3,a3,-1904 # ffffffffc02050a8 <commands+0xa58>
ffffffffc0201820:	00003617          	auipc	a2,0x3
ffffffffc0201824:	6b860613          	addi	a2,a2,1720 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201828:	1b000593          	li	a1,432
ffffffffc020182c:	00003517          	auipc	a0,0x3
ffffffffc0201830:	5ac50513          	addi	a0,a0,1452 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201834:	8cffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201838:	00003697          	auipc	a3,0x3
ffffffffc020183c:	7a868693          	addi	a3,a3,1960 # ffffffffc0204fe0 <commands+0x990>
ffffffffc0201840:	00003617          	auipc	a2,0x3
ffffffffc0201844:	69860613          	addi	a2,a2,1688 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201848:	1a800593          	li	a1,424
ffffffffc020184c:	00003517          	auipc	a0,0x3
ffffffffc0201850:	58c50513          	addi	a0,a0,1420 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201854:	8affe0ef          	jal	ra,ffffffffc0200102 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;//获取第二级页表的虚拟地址
ffffffffc0201858:	86d6                	mv	a3,s5
ffffffffc020185a:	00003617          	auipc	a2,0x3
ffffffffc020185e:	55660613          	addi	a2,a2,1366 # ffffffffc0204db0 <commands+0x760>
ffffffffc0201862:	1a700593          	li	a1,423
ffffffffc0201866:	00003517          	auipc	a0,0x3
ffffffffc020186a:	57250513          	addi	a0,a0,1394 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020186e:	895fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201872:	00003697          	auipc	a3,0x3
ffffffffc0201876:	7ce68693          	addi	a3,a3,1998 # ffffffffc0205040 <commands+0x9f0>
ffffffffc020187a:	00003617          	auipc	a2,0x3
ffffffffc020187e:	65e60613          	addi	a2,a2,1630 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201882:	1b500593          	li	a1,437
ffffffffc0201886:	00003517          	auipc	a0,0x3
ffffffffc020188a:	55250513          	addi	a0,a0,1362 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020188e:	875fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201892:	00004697          	auipc	a3,0x4
ffffffffc0201896:	87668693          	addi	a3,a3,-1930 # ffffffffc0205108 <commands+0xab8>
ffffffffc020189a:	00003617          	auipc	a2,0x3
ffffffffc020189e:	63e60613          	addi	a2,a2,1598 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02018a2:	1b400593          	li	a1,436
ffffffffc02018a6:	00003517          	auipc	a0,0x3
ffffffffc02018aa:	53250513          	addi	a0,a0,1330 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02018ae:	855fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02018b2:	00004697          	auipc	a3,0x4
ffffffffc02018b6:	83e68693          	addi	a3,a3,-1986 # ffffffffc02050f0 <commands+0xaa0>
ffffffffc02018ba:	00003617          	auipc	a2,0x3
ffffffffc02018be:	61e60613          	addi	a2,a2,1566 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02018c2:	1b300593          	li	a1,435
ffffffffc02018c6:	00003517          	auipc	a0,0x3
ffffffffc02018ca:	51250513          	addi	a0,a0,1298 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02018ce:	835fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02018d2:	00003697          	auipc	a3,0x3
ffffffffc02018d6:	7ee68693          	addi	a3,a3,2030 # ffffffffc02050c0 <commands+0xa70>
ffffffffc02018da:	00003617          	auipc	a2,0x3
ffffffffc02018de:	5fe60613          	addi	a2,a2,1534 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02018e2:	1b200593          	li	a1,434
ffffffffc02018e6:	00003517          	auipc	a0,0x3
ffffffffc02018ea:	4f250513          	addi	a0,a0,1266 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02018ee:	815fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02018f2:	00004697          	auipc	a3,0x4
ffffffffc02018f6:	98668693          	addi	a3,a3,-1658 # ffffffffc0205278 <commands+0xc28>
ffffffffc02018fa:	00003617          	auipc	a2,0x3
ffffffffc02018fe:	5de60613          	addi	a2,a2,1502 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201902:	1e000593          	li	a1,480
ffffffffc0201906:	00003517          	auipc	a0,0x3
ffffffffc020190a:	4d250513          	addi	a0,a0,1234 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020190e:	ff4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201912:	00003697          	auipc	a3,0x3
ffffffffc0201916:	77e68693          	addi	a3,a3,1918 # ffffffffc0205090 <commands+0xa40>
ffffffffc020191a:	00003617          	auipc	a2,0x3
ffffffffc020191e:	5be60613          	addi	a2,a2,1470 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201922:	1af00593          	li	a1,431
ffffffffc0201926:	00003517          	auipc	a0,0x3
ffffffffc020192a:	4b250513          	addi	a0,a0,1202 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020192e:	fd4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201932:	00003697          	auipc	a3,0x3
ffffffffc0201936:	74e68693          	addi	a3,a3,1870 # ffffffffc0205080 <commands+0xa30>
ffffffffc020193a:	00003617          	auipc	a2,0x3
ffffffffc020193e:	59e60613          	addi	a2,a2,1438 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201942:	1ae00593          	li	a1,430
ffffffffc0201946:	00003517          	auipc	a0,0x3
ffffffffc020194a:	49250513          	addi	a0,a0,1170 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020194e:	fb4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201952:	00004697          	auipc	a3,0x4
ffffffffc0201956:	82668693          	addi	a3,a3,-2010 # ffffffffc0205178 <commands+0xb28>
ffffffffc020195a:	00003617          	auipc	a2,0x3
ffffffffc020195e:	57e60613          	addi	a2,a2,1406 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201962:	1f000593          	li	a1,496
ffffffffc0201966:	00003517          	auipc	a0,0x3
ffffffffc020196a:	47250513          	addi	a0,a0,1138 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020196e:	f94fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201972:	00003697          	auipc	a3,0x3
ffffffffc0201976:	6fe68693          	addi	a3,a3,1790 # ffffffffc0205070 <commands+0xa20>
ffffffffc020197a:	00003617          	auipc	a2,0x3
ffffffffc020197e:	55e60613          	addi	a2,a2,1374 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201982:	1ad00593          	li	a1,429
ffffffffc0201986:	00003517          	auipc	a0,0x3
ffffffffc020198a:	45250513          	addi	a0,a0,1106 # ffffffffc0204dd8 <commands+0x788>
ffffffffc020198e:	f74fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201992:	00003697          	auipc	a3,0x3
ffffffffc0201996:	63668693          	addi	a3,a3,1590 # ffffffffc0204fc8 <commands+0x978>
ffffffffc020199a:	00003617          	auipc	a2,0x3
ffffffffc020199e:	53e60613          	addi	a2,a2,1342 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02019a2:	1ba00593          	li	a1,442
ffffffffc02019a6:	00003517          	auipc	a0,0x3
ffffffffc02019aa:	43250513          	addi	a0,a0,1074 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02019ae:	f54fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02019b2:	00003697          	auipc	a3,0x3
ffffffffc02019b6:	76e68693          	addi	a3,a3,1902 # ffffffffc0205120 <commands+0xad0>
ffffffffc02019ba:	00003617          	auipc	a2,0x3
ffffffffc02019be:	51e60613          	addi	a2,a2,1310 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02019c2:	1b700593          	li	a1,439
ffffffffc02019c6:	00003517          	auipc	a0,0x3
ffffffffc02019ca:	41250513          	addi	a0,a0,1042 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02019ce:	f34fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02019d2:	00003697          	auipc	a3,0x3
ffffffffc02019d6:	5de68693          	addi	a3,a3,1502 # ffffffffc0204fb0 <commands+0x960>
ffffffffc02019da:	00003617          	auipc	a2,0x3
ffffffffc02019de:	4fe60613          	addi	a2,a2,1278 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02019e2:	1b600593          	li	a1,438
ffffffffc02019e6:	00003517          	auipc	a0,0x3
ffffffffc02019ea:	3f250513          	addi	a0,a0,1010 # ffffffffc0204dd8 <commands+0x788>
ffffffffc02019ee:	f14fe0ef          	jal	ra,ffffffffc0200102 <__panic>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02019f2:	00003617          	auipc	a2,0x3
ffffffffc02019f6:	3be60613          	addi	a2,a2,958 # ffffffffc0204db0 <commands+0x760>
ffffffffc02019fa:	07100593          	li	a1,113
ffffffffc02019fe:	00003517          	auipc	a0,0x3
ffffffffc0201a02:	37a50513          	addi	a0,a0,890 # ffffffffc0204d78 <commands+0x728>
ffffffffc0201a06:	efcfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);//检查页目录的引用计数是否为1，确保页目录不会被错误地释放
ffffffffc0201a0a:	00003697          	auipc	a3,0x3
ffffffffc0201a0e:	74668693          	addi	a3,a3,1862 # ffffffffc0205150 <commands+0xb00>
ffffffffc0201a12:	00003617          	auipc	a2,0x3
ffffffffc0201a16:	4c660613          	addi	a2,a2,1222 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201a1a:	1c100593          	li	a1,449
ffffffffc0201a1e:	00003517          	auipc	a0,0x3
ffffffffc0201a22:	3ba50513          	addi	a0,a0,954 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201a26:	edcfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201a2a:	00003697          	auipc	a3,0x3
ffffffffc0201a2e:	6de68693          	addi	a3,a3,1758 # ffffffffc0205108 <commands+0xab8>
ffffffffc0201a32:	00003617          	auipc	a2,0x3
ffffffffc0201a36:	4a660613          	addi	a2,a2,1190 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201a3a:	1bf00593          	li	a1,447
ffffffffc0201a3e:	00003517          	auipc	a0,0x3
ffffffffc0201a42:	39a50513          	addi	a0,a0,922 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201a46:	ebcfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201a4a:	00003697          	auipc	a3,0x3
ffffffffc0201a4e:	6ee68693          	addi	a3,a3,1774 # ffffffffc0205138 <commands+0xae8>
ffffffffc0201a52:	00003617          	auipc	a2,0x3
ffffffffc0201a56:	48660613          	addi	a2,a2,1158 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201a5a:	1be00593          	li	a1,446
ffffffffc0201a5e:	00003517          	auipc	a0,0x3
ffffffffc0201a62:	37a50513          	addi	a0,a0,890 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201a66:	e9cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201a6a:	00003697          	auipc	a3,0x3
ffffffffc0201a6e:	69e68693          	addi	a3,a3,1694 # ffffffffc0205108 <commands+0xab8>
ffffffffc0201a72:	00003617          	auipc	a2,0x3
ffffffffc0201a76:	46660613          	addi	a2,a2,1126 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201a7a:	1bb00593          	li	a1,443
ffffffffc0201a7e:	00003517          	auipc	a0,0x3
ffffffffc0201a82:	35a50513          	addi	a0,a0,858 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201a86:	e7cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201a8a:	00003697          	auipc	a3,0x3
ffffffffc0201a8e:	7d668693          	addi	a3,a3,2006 # ffffffffc0205260 <commands+0xc10>
ffffffffc0201a92:	00003617          	auipc	a2,0x3
ffffffffc0201a96:	44660613          	addi	a2,a2,1094 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201a9a:	1df00593          	li	a1,479
ffffffffc0201a9e:	00003517          	auipc	a0,0x3
ffffffffc0201aa2:	33a50513          	addi	a0,a0,826 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201aa6:	e5cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201aaa:	00003697          	auipc	a3,0x3
ffffffffc0201aae:	77e68693          	addi	a3,a3,1918 # ffffffffc0205228 <commands+0xbd8>
ffffffffc0201ab2:	00003617          	auipc	a2,0x3
ffffffffc0201ab6:	42660613          	addi	a2,a2,1062 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201aba:	1de00593          	li	a1,478
ffffffffc0201abe:	00003517          	auipc	a0,0x3
ffffffffc0201ac2:	31a50513          	addi	a0,a0,794 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201ac6:	e3cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0201aca:	00003697          	auipc	a3,0x3
ffffffffc0201ace:	74668693          	addi	a3,a3,1862 # ffffffffc0205210 <commands+0xbc0>
ffffffffc0201ad2:	00003617          	auipc	a2,0x3
ffffffffc0201ad6:	40660613          	addi	a2,a2,1030 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201ada:	1da00593          	li	a1,474
ffffffffc0201ade:	00003517          	auipc	a0,0x3
ffffffffc0201ae2:	2fa50513          	addi	a0,a0,762 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201ae6:	e1cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201aea:	00003697          	auipc	a3,0x3
ffffffffc0201aee:	68e68693          	addi	a3,a3,1678 # ffffffffc0205178 <commands+0xb28>
ffffffffc0201af2:	00003617          	auipc	a2,0x3
ffffffffc0201af6:	3e660613          	addi	a2,a2,998 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201afa:	1c800593          	li	a1,456
ffffffffc0201afe:	00003517          	auipc	a0,0x3
ffffffffc0201b02:	2da50513          	addi	a0,a0,730 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201b06:	dfcfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201b0a:	00003697          	auipc	a3,0x3
ffffffffc0201b0e:	4a668693          	addi	a3,a3,1190 # ffffffffc0204fb0 <commands+0x960>
ffffffffc0201b12:	00003617          	auipc	a2,0x3
ffffffffc0201b16:	3c660613          	addi	a2,a2,966 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201b1a:	1a300593          	li	a1,419
ffffffffc0201b1e:	00003517          	auipc	a0,0x3
ffffffffc0201b22:	2ba50513          	addi	a0,a0,698 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201b26:	ddcfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));//获取第一级页表的物理地址，然后将其转换为虚拟地址
ffffffffc0201b2a:	00003617          	auipc	a2,0x3
ffffffffc0201b2e:	28660613          	addi	a2,a2,646 # ffffffffc0204db0 <commands+0x760>
ffffffffc0201b32:	1a600593          	li	a1,422
ffffffffc0201b36:	00003517          	auipc	a0,0x3
ffffffffc0201b3a:	2a250513          	addi	a0,a0,674 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201b3e:	dc4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201b42:	00003697          	auipc	a3,0x3
ffffffffc0201b46:	48668693          	addi	a3,a3,1158 # ffffffffc0204fc8 <commands+0x978>
ffffffffc0201b4a:	00003617          	auipc	a2,0x3
ffffffffc0201b4e:	38e60613          	addi	a2,a2,910 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201b52:	1a400593          	li	a1,420
ffffffffc0201b56:	00003517          	auipc	a0,0x3
ffffffffc0201b5a:	28250513          	addi	a0,a0,642 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201b5e:	da4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201b62:	00003697          	auipc	a3,0x3
ffffffffc0201b66:	4de68693          	addi	a3,a3,1246 # ffffffffc0205040 <commands+0x9f0>
ffffffffc0201b6a:	00003617          	auipc	a2,0x3
ffffffffc0201b6e:	36e60613          	addi	a2,a2,878 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201b72:	1ac00593          	li	a1,428
ffffffffc0201b76:	00003517          	auipc	a0,0x3
ffffffffc0201b7a:	26250513          	addi	a0,a0,610 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201b7e:	d84fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201b82:	00003697          	auipc	a3,0x3
ffffffffc0201b86:	79e68693          	addi	a3,a3,1950 # ffffffffc0205320 <commands+0xcd0>
ffffffffc0201b8a:	00003617          	auipc	a2,0x3
ffffffffc0201b8e:	34e60613          	addi	a2,a2,846 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201b92:	1e800593          	li	a1,488
ffffffffc0201b96:	00003517          	auipc	a0,0x3
ffffffffc0201b9a:	24250513          	addi	a0,a0,578 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201b9e:	d64fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201ba2:	00003697          	auipc	a3,0x3
ffffffffc0201ba6:	74668693          	addi	a3,a3,1862 # ffffffffc02052e8 <commands+0xc98>
ffffffffc0201baa:	00003617          	auipc	a2,0x3
ffffffffc0201bae:	32e60613          	addi	a2,a2,814 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201bb2:	1e500593          	li	a1,485
ffffffffc0201bb6:	00003517          	auipc	a0,0x3
ffffffffc0201bba:	22250513          	addi	a0,a0,546 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201bbe:	d44fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201bc2:	00003697          	auipc	a3,0x3
ffffffffc0201bc6:	6f668693          	addi	a3,a3,1782 # ffffffffc02052b8 <commands+0xc68>
ffffffffc0201bca:	00003617          	auipc	a2,0x3
ffffffffc0201bce:	30e60613          	addi	a2,a2,782 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201bd2:	1e100593          	li	a1,481
ffffffffc0201bd6:	00003517          	auipc	a0,0x3
ffffffffc0201bda:	20250513          	addi	a0,a0,514 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201bde:	d24fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201be2 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201be2:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0201be6:	8082                	ret

ffffffffc0201be8 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201be8:	7179                	addi	sp,sp,-48
ffffffffc0201bea:	e84a                	sd	s2,16(sp)
ffffffffc0201bec:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0201bee:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0201bf0:	f022                	sd	s0,32(sp)
ffffffffc0201bf2:	ec26                	sd	s1,24(sp)
ffffffffc0201bf4:	e44e                	sd	s3,8(sp)
ffffffffc0201bf6:	f406                	sd	ra,40(sp)
ffffffffc0201bf8:	84ae                	mv	s1,a1
ffffffffc0201bfa:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0201bfc:	eedfe0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0201c00:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0201c02:	cd09                	beqz	a0,ffffffffc0201c1c <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0201c04:	85aa                	mv	a1,a0
ffffffffc0201c06:	86ce                	mv	a3,s3
ffffffffc0201c08:	8626                	mv	a2,s1
ffffffffc0201c0a:	854a                	mv	a0,s2
ffffffffc0201c0c:	ad2ff0ef          	jal	ra,ffffffffc0200ede <page_insert>
ffffffffc0201c10:	ed21                	bnez	a0,ffffffffc0201c68 <pgdir_alloc_page+0x80>
        if (swap_init_ok) {
ffffffffc0201c12:	00010797          	auipc	a5,0x10
ffffffffc0201c16:	94e7a783          	lw	a5,-1714(a5) # ffffffffc0211560 <swap_init_ok>
ffffffffc0201c1a:	eb89                	bnez	a5,ffffffffc0201c2c <pgdir_alloc_page+0x44>
}
ffffffffc0201c1c:	70a2                	ld	ra,40(sp)
ffffffffc0201c1e:	8522                	mv	a0,s0
ffffffffc0201c20:	7402                	ld	s0,32(sp)
ffffffffc0201c22:	64e2                	ld	s1,24(sp)
ffffffffc0201c24:	6942                	ld	s2,16(sp)
ffffffffc0201c26:	69a2                	ld	s3,8(sp)
ffffffffc0201c28:	6145                	addi	sp,sp,48
ffffffffc0201c2a:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0201c2c:	4681                	li	a3,0
ffffffffc0201c2e:	8622                	mv	a2,s0
ffffffffc0201c30:	85a6                	mv	a1,s1
ffffffffc0201c32:	00010517          	auipc	a0,0x10
ffffffffc0201c36:	90e53503          	ld	a0,-1778(a0) # ffffffffc0211540 <check_mm_struct>
ffffffffc0201c3a:	102010ef          	jal	ra,ffffffffc0202d3c <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0201c3e:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0201c40:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0201c42:	4785                	li	a5,1
ffffffffc0201c44:	fcf70ce3          	beq	a4,a5,ffffffffc0201c1c <pgdir_alloc_page+0x34>
ffffffffc0201c48:	00003697          	auipc	a3,0x3
ffffffffc0201c4c:	72068693          	addi	a3,a3,1824 # ffffffffc0205368 <commands+0xd18>
ffffffffc0201c50:	00003617          	auipc	a2,0x3
ffffffffc0201c54:	28860613          	addi	a2,a2,648 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201c58:	18100593          	li	a1,385
ffffffffc0201c5c:	00003517          	auipc	a0,0x3
ffffffffc0201c60:	17c50513          	addi	a0,a0,380 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201c64:	c9efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c68:	100027f3          	csrr	a5,sstatus
ffffffffc0201c6c:	8b89                	andi	a5,a5,2
ffffffffc0201c6e:	eb99                	bnez	a5,ffffffffc0201c84 <pgdir_alloc_page+0x9c>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201c70:	00010797          	auipc	a5,0x10
ffffffffc0201c74:	8c07b783          	ld	a5,-1856(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0201c78:	739c                	ld	a5,32(a5)
ffffffffc0201c7a:	8522                	mv	a0,s0
ffffffffc0201c7c:	4585                	li	a1,1
ffffffffc0201c7e:	9782                	jalr	a5
            return NULL;
ffffffffc0201c80:	4401                	li	s0,0
ffffffffc0201c82:	bf69                	j	ffffffffc0201c1c <pgdir_alloc_page+0x34>
        intr_disable();
ffffffffc0201c84:	86bfe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201c88:	00010797          	auipc	a5,0x10
ffffffffc0201c8c:	8a87b783          	ld	a5,-1880(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0201c90:	739c                	ld	a5,32(a5)
ffffffffc0201c92:	8522                	mv	a0,s0
ffffffffc0201c94:	4585                	li	a1,1
ffffffffc0201c96:	9782                	jalr	a5
            return NULL;
ffffffffc0201c98:	4401                	li	s0,0
        intr_enable();
ffffffffc0201c9a:	84ffe0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0201c9e:	bfbd                	j	ffffffffc0201c1c <pgdir_alloc_page+0x34>

ffffffffc0201ca0 <kmalloc>:
}

void *kmalloc(size_t n) {//分配至少n个连续的字节， 这里实现得不精细， 占用的只能是整数个页
ffffffffc0201ca0:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201ca2:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {//分配至少n个连续的字节， 这里实现得不精细， 占用的只能是整数个页
ffffffffc0201ca4:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201ca6:	fff50713          	addi	a4,a0,-1
ffffffffc0201caa:	17f9                	addi	a5,a5,-2
ffffffffc0201cac:	04e7ea63          	bltu	a5,a4,ffffffffc0201d00 <kmalloc+0x60>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;//向上取整到整数个页
ffffffffc0201cb0:	6785                	lui	a5,0x1
ffffffffc0201cb2:	17fd                	addi	a5,a5,-1
ffffffffc0201cb4:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc0201cb6:	8131                	srli	a0,a0,0xc
ffffffffc0201cb8:	e31fe0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
    assert(base != NULL);//如果分配失败就直接panic
ffffffffc0201cbc:	cd3d                	beqz	a0,ffffffffc0201d3a <kmalloc+0x9a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201cbe:	00010797          	auipc	a5,0x10
ffffffffc0201cc2:	86a7b783          	ld	a5,-1942(a5) # ffffffffc0211528 <pages>
ffffffffc0201cc6:	8d1d                	sub	a0,a0,a5
ffffffffc0201cc8:	00004697          	auipc	a3,0x4
ffffffffc0201ccc:	4f86b683          	ld	a3,1272(a3) # ffffffffc02061c0 <error_string+0x38>
ffffffffc0201cd0:	850d                	srai	a0,a0,0x3
ffffffffc0201cd2:	02d50533          	mul	a0,a0,a3
ffffffffc0201cd6:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201cda:	00010717          	auipc	a4,0x10
ffffffffc0201cde:	84673703          	ld	a4,-1978(a4) # ffffffffc0211520 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201ce2:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ce4:	00c51793          	slli	a5,a0,0xc
ffffffffc0201ce8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201cea:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201cec:	02e7fa63          	bgeu	a5,a4,ffffffffc0201d20 <kmalloc+0x80>
    ptr = page2kva(base);//分配的内存的起始位置（ 虚拟地址）  page2kva, 就是page_to_kernel_virtual_address
    return ptr;
}
ffffffffc0201cf0:	60a2                	ld	ra,8(sp)
ffffffffc0201cf2:	00010797          	auipc	a5,0x10
ffffffffc0201cf6:	8467b783          	ld	a5,-1978(a5) # ffffffffc0211538 <va_pa_offset>
ffffffffc0201cfa:	953e                	add	a0,a0,a5
ffffffffc0201cfc:	0141                	addi	sp,sp,16
ffffffffc0201cfe:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201d00:	00003697          	auipc	a3,0x3
ffffffffc0201d04:	68068693          	addi	a3,a3,1664 # ffffffffc0205380 <commands+0xd30>
ffffffffc0201d08:	00003617          	auipc	a2,0x3
ffffffffc0201d0c:	1d060613          	addi	a2,a2,464 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201d10:	1f800593          	li	a1,504
ffffffffc0201d14:	00003517          	auipc	a0,0x3
ffffffffc0201d18:	0c450513          	addi	a0,a0,196 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201d1c:	be6fe0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0201d20:	86aa                	mv	a3,a0
ffffffffc0201d22:	00003617          	auipc	a2,0x3
ffffffffc0201d26:	08e60613          	addi	a2,a2,142 # ffffffffc0204db0 <commands+0x760>
ffffffffc0201d2a:	07100593          	li	a1,113
ffffffffc0201d2e:	00003517          	auipc	a0,0x3
ffffffffc0201d32:	04a50513          	addi	a0,a0,74 # ffffffffc0204d78 <commands+0x728>
ffffffffc0201d36:	bccfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(base != NULL);//如果分配失败就直接panic
ffffffffc0201d3a:	00003697          	auipc	a3,0x3
ffffffffc0201d3e:	66668693          	addi	a3,a3,1638 # ffffffffc02053a0 <commands+0xd50>
ffffffffc0201d42:	00003617          	auipc	a2,0x3
ffffffffc0201d46:	19660613          	addi	a2,a2,406 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201d4a:	1fb00593          	li	a1,507
ffffffffc0201d4e:	00003517          	auipc	a0,0x3
ffffffffc0201d52:	08a50513          	addi	a0,a0,138 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201d56:	bacfe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201d5a <kfree>:

void kfree(void *ptr, size_t n) {//从某个位置开始释放n个字节
ffffffffc0201d5a:	1101                	addi	sp,sp,-32
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201d5c:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {//从某个位置开始释放n个字节
ffffffffc0201d5e:	ec06                	sd	ra,24(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201d60:	fff58713          	addi	a4,a1,-1
ffffffffc0201d64:	17f9                	addi	a5,a5,-2
ffffffffc0201d66:	0ae7ee63          	bltu	a5,a4,ffffffffc0201e22 <kfree+0xc8>
    assert(ptr != NULL);
ffffffffc0201d6a:	cd41                	beqz	a0,ffffffffc0201e02 <kfree+0xa8>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0201d6c:	6785                	lui	a5,0x1
ffffffffc0201d6e:	17fd                	addi	a5,a5,-1
ffffffffc0201d70:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201d72:	c02007b7          	lui	a5,0xc0200
ffffffffc0201d76:	81b1                	srli	a1,a1,0xc
ffffffffc0201d78:	06f56863          	bltu	a0,a5,ffffffffc0201de8 <kfree+0x8e>
ffffffffc0201d7c:	0000f697          	auipc	a3,0xf
ffffffffc0201d80:	7bc6b683          	ld	a3,1980(a3) # ffffffffc0211538 <va_pa_offset>
ffffffffc0201d84:	8d15                	sub	a0,a0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201d86:	8131                	srli	a0,a0,0xc
ffffffffc0201d88:	0000f797          	auipc	a5,0xf
ffffffffc0201d8c:	7987b783          	ld	a5,1944(a5) # ffffffffc0211520 <npage>
ffffffffc0201d90:	04f57a63          	bgeu	a0,a5,ffffffffc0201de4 <kfree+0x8a>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d94:	fff806b7          	lui	a3,0xfff80
ffffffffc0201d98:	9536                	add	a0,a0,a3
ffffffffc0201d9a:	00351793          	slli	a5,a0,0x3
ffffffffc0201d9e:	953e                	add	a0,a0,a5
ffffffffc0201da0:	050e                	slli	a0,a0,0x3
ffffffffc0201da2:	0000f797          	auipc	a5,0xf
ffffffffc0201da6:	7867b783          	ld	a5,1926(a5) # ffffffffc0211528 <pages>
ffffffffc0201daa:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201dac:	100027f3          	csrr	a5,sstatus
ffffffffc0201db0:	8b89                	andi	a5,a5,2
ffffffffc0201db2:	eb89                	bnez	a5,ffffffffc0201dc4 <kfree+0x6a>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201db4:	0000f797          	auipc	a5,0xf
ffffffffc0201db8:	77c7b783          	ld	a5,1916(a5) # ffffffffc0211530 <pmm_manager>
    base = kva2page(ptr);//kernel_virtual_address_to_page
    free_pages(base, num_pages);
}
ffffffffc0201dbc:	60e2                	ld	ra,24(sp)
    { pmm_manager->free_pages(base, n); }
ffffffffc0201dbe:	739c                	ld	a5,32(a5)
}
ffffffffc0201dc0:	6105                	addi	sp,sp,32
    { pmm_manager->free_pages(base, n); }
ffffffffc0201dc2:	8782                	jr	a5
        intr_disable();
ffffffffc0201dc4:	e42a                	sd	a0,8(sp)
ffffffffc0201dc6:	e02e                	sd	a1,0(sp)
ffffffffc0201dc8:	f26fe0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0201dcc:	0000f797          	auipc	a5,0xf
ffffffffc0201dd0:	7647b783          	ld	a5,1892(a5) # ffffffffc0211530 <pmm_manager>
ffffffffc0201dd4:	6582                	ld	a1,0(sp)
ffffffffc0201dd6:	6522                	ld	a0,8(sp)
ffffffffc0201dd8:	739c                	ld	a5,32(a5)
ffffffffc0201dda:	9782                	jalr	a5
}
ffffffffc0201ddc:	60e2                	ld	ra,24(sp)
ffffffffc0201dde:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201de0:	f08fe06f          	j	ffffffffc02004e8 <intr_enable>
ffffffffc0201de4:	ccdfe0ef          	jal	ra,ffffffffc0200ab0 <pa2page.part.0>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0201de8:	86aa                	mv	a3,a0
ffffffffc0201dea:	00003617          	auipc	a2,0x3
ffffffffc0201dee:	08660613          	addi	a2,a2,134 # ffffffffc0204e70 <commands+0x820>
ffffffffc0201df2:	07300593          	li	a1,115
ffffffffc0201df6:	00003517          	auipc	a0,0x3
ffffffffc0201dfa:	f8250513          	addi	a0,a0,-126 # ffffffffc0204d78 <commands+0x728>
ffffffffc0201dfe:	b04fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(ptr != NULL);
ffffffffc0201e02:	00003697          	auipc	a3,0x3
ffffffffc0201e06:	5ae68693          	addi	a3,a3,1454 # ffffffffc02053b0 <commands+0xd60>
ffffffffc0201e0a:	00003617          	auipc	a2,0x3
ffffffffc0201e0e:	0ce60613          	addi	a2,a2,206 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201e12:	20200593          	li	a1,514
ffffffffc0201e16:	00003517          	auipc	a0,0x3
ffffffffc0201e1a:	fc250513          	addi	a0,a0,-62 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201e1e:	ae4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0201e22:	00003697          	auipc	a3,0x3
ffffffffc0201e26:	55e68693          	addi	a3,a3,1374 # ffffffffc0205380 <commands+0xd30>
ffffffffc0201e2a:	00003617          	auipc	a2,0x3
ffffffffc0201e2e:	0ae60613          	addi	a2,a2,174 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201e32:	20100593          	li	a1,513
ffffffffc0201e36:	00003517          	auipc	a0,0x3
ffffffffc0201e3a:	fa250513          	addi	a0,a0,-94 # ffffffffc0204dd8 <commands+0x788>
ffffffffc0201e3e:	ac4fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201e42 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0201e42:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);//next 是我们想插入的区间， 这里顺便检验了start < end
ffffffffc0201e44:	00003697          	auipc	a3,0x3
ffffffffc0201e48:	57c68693          	addi	a3,a3,1404 # ffffffffc02053c0 <commands+0xd70>
ffffffffc0201e4c:	00003617          	auipc	a2,0x3
ffffffffc0201e50:	08c60613          	addi	a2,a2,140 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201e54:	07f00593          	li	a1,127
ffffffffc0201e58:	00003517          	auipc	a0,0x3
ffffffffc0201e5c:	58850513          	addi	a0,a0,1416 # ffffffffc02053e0 <commands+0xd90>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0201e60:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);//next 是我们想插入的区间， 这里顺便检验了start < end
ffffffffc0201e62:	aa0fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201e66 <mm_create>:
mm_create(void) {
ffffffffc0201e66:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201e68:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0201e6c:	e022                	sd	s0,0(sp)
ffffffffc0201e6e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201e70:	e31ff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
ffffffffc0201e74:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0201e76:	c105                	beqz	a0,ffffffffc0201e96 <mm_create+0x30>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201e78:	e408                	sd	a0,8(s0)
ffffffffc0201e7a:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0201e7c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0201e80:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0201e84:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc0201e88:	0000f797          	auipc	a5,0xf
ffffffffc0201e8c:	6d87a783          	lw	a5,1752(a5) # ffffffffc0211560 <swap_init_ok>
ffffffffc0201e90:	eb81                	bnez	a5,ffffffffc0201ea0 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc0201e92:	02053423          	sd	zero,40(a0)
}
ffffffffc0201e96:	60a2                	ld	ra,8(sp)
ffffffffc0201e98:	8522                	mv	a0,s0
ffffffffc0201e9a:	6402                	ld	s0,0(sp)
ffffffffc0201e9c:	0141                	addi	sp,sp,16
ffffffffc0201e9e:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc0201ea0:	691000ef          	jal	ra,ffffffffc0202d30 <swap_init_mm>
}
ffffffffc0201ea4:	60a2                	ld	ra,8(sp)
ffffffffc0201ea6:	8522                	mv	a0,s0
ffffffffc0201ea8:	6402                	ld	s0,0(sp)
ffffffffc0201eaa:	0141                	addi	sp,sp,16
ffffffffc0201eac:	8082                	ret

ffffffffc0201eae <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0201eae:	1101                	addi	sp,sp,-32
ffffffffc0201eb0:	e04a                	sd	s2,0(sp)
ffffffffc0201eb2:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201eb4:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0201eb8:	e822                	sd	s0,16(sp)
ffffffffc0201eba:	e426                	sd	s1,8(sp)
ffffffffc0201ebc:	ec06                	sd	ra,24(sp)
ffffffffc0201ebe:	84ae                	mv	s1,a1
ffffffffc0201ec0:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201ec2:	ddfff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
    if (vma != NULL) {
ffffffffc0201ec6:	c509                	beqz	a0,ffffffffc0201ed0 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0201ec8:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0201ecc:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0201ece:	ed00                	sd	s0,24(a0)
}
ffffffffc0201ed0:	60e2                	ld	ra,24(sp)
ffffffffc0201ed2:	6442                	ld	s0,16(sp)
ffffffffc0201ed4:	64a2                	ld	s1,8(sp)
ffffffffc0201ed6:	6902                	ld	s2,0(sp)
ffffffffc0201ed8:	6105                	addi	sp,sp,32
ffffffffc0201eda:	8082                	ret

ffffffffc0201edc <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0201edc:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0201ede:	c505                	beqz	a0,ffffffffc0201f06 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0201ee0:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0201ee2:	c501                	beqz	a0,ffffffffc0201eea <find_vma+0xe>
ffffffffc0201ee4:	651c                	ld	a5,8(a0)
ffffffffc0201ee6:	02f5f263          	bgeu	a1,a5,ffffffffc0201f0a <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201eea:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0201eec:	00f68d63          	beq	a3,a5,ffffffffc0201f06 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0201ef0:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201ef4:	00e5e663          	bltu	a1,a4,ffffffffc0201f00 <find_vma+0x24>
ffffffffc0201ef8:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201efc:	00e5ec63          	bltu	a1,a4,ffffffffc0201f14 <find_vma+0x38>
ffffffffc0201f00:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0201f02:	fef697e3          	bne	a3,a5,ffffffffc0201ef0 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0201f06:	4501                	li	a0,0
}
ffffffffc0201f08:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0201f0a:	691c                	ld	a5,16(a0)
ffffffffc0201f0c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0201eea <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0201f10:	ea88                	sd	a0,16(a3)
ffffffffc0201f12:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0201f14:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0201f18:	ea88                	sd	a0,16(a3)
ffffffffc0201f1a:	8082                	ret

ffffffffc0201f1c <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f1c:	6590                	ld	a2,8(a1)
ffffffffc0201f1e:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0201f22:	1141                	addi	sp,sp,-16
ffffffffc0201f24:	e406                	sd	ra,8(sp)
ffffffffc0201f26:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f28:	01066763          	bltu	a2,a6,ffffffffc0201f36 <insert_vma_struct+0x1a>
ffffffffc0201f2c:	a085                	j	ffffffffc0201f8c <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

    list_entry_t *le = list;
    while ((le = list_next(le)) != list) {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0201f2e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201f32:	04e66863          	bltu	a2,a4,ffffffffc0201f82 <insert_vma_struct+0x66>
ffffffffc0201f36:	86be                	mv	a3,a5
ffffffffc0201f38:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list) {
ffffffffc0201f3a:	fef51ae3          	bne	a0,a5,ffffffffc0201f2e <insert_vma_struct+0x12>
    }
    //保证插入后所有vma_struct按照区间左端点有序排列
    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0201f3e:	02a68463          	beq	a3,a0,ffffffffc0201f66 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201f42:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201f46:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201f4a:	08e8f163          	bgeu	a7,a4,ffffffffc0201fcc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f4e:	04e66f63          	bltu	a2,a4,ffffffffc0201fac <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0201f52:	00f50a63          	beq	a0,a5,ffffffffc0201f66 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0201f56:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f5a:	05076963          	bltu	a4,a6,ffffffffc0201fac <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);//next 是我们想插入的区间， 这里顺便检验了start < end
ffffffffc0201f5e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201f62:	02c77363          	bgeu	a4,a2,ffffffffc0201f88 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0201f66:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201f68:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201f6a:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201f6e:	e390                	sd	a2,0(a5)
ffffffffc0201f70:	e690                	sd	a2,8(a3)
}
ffffffffc0201f72:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201f74:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201f76:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0201f78:	0017079b          	addiw	a5,a4,1
ffffffffc0201f7c:	d11c                	sw	a5,32(a0)
}
ffffffffc0201f7e:	0141                	addi	sp,sp,16
ffffffffc0201f80:	8082                	ret
    if (le_prev != list) {
ffffffffc0201f82:	fca690e3          	bne	a3,a0,ffffffffc0201f42 <insert_vma_struct+0x26>
ffffffffc0201f86:	bfd1                	j	ffffffffc0201f5a <insert_vma_struct+0x3e>
ffffffffc0201f88:	ebbff0ef          	jal	ra,ffffffffc0201e42 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f8c:	00003697          	auipc	a3,0x3
ffffffffc0201f90:	46468693          	addi	a3,a3,1124 # ffffffffc02053f0 <commands+0xda0>
ffffffffc0201f94:	00003617          	auipc	a2,0x3
ffffffffc0201f98:	f4460613          	addi	a2,a2,-188 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201f9c:	08600593          	li	a1,134
ffffffffc0201fa0:	00003517          	auipc	a0,0x3
ffffffffc0201fa4:	44050513          	addi	a0,a0,1088 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0201fa8:	95afe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201fac:	00003697          	auipc	a3,0x3
ffffffffc0201fb0:	48468693          	addi	a3,a3,1156 # ffffffffc0205430 <commands+0xde0>
ffffffffc0201fb4:	00003617          	auipc	a2,0x3
ffffffffc0201fb8:	f2460613          	addi	a2,a2,-220 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201fbc:	07e00593          	li	a1,126
ffffffffc0201fc0:	00003517          	auipc	a0,0x3
ffffffffc0201fc4:	42050513          	addi	a0,a0,1056 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0201fc8:	93afe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201fcc:	00003697          	auipc	a3,0x3
ffffffffc0201fd0:	44468693          	addi	a3,a3,1092 # ffffffffc0205410 <commands+0xdc0>
ffffffffc0201fd4:	00003617          	auipc	a2,0x3
ffffffffc0201fd8:	f0460613          	addi	a2,a2,-252 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0201fdc:	07d00593          	li	a1,125
ffffffffc0201fe0:	00003517          	auipc	a0,0x3
ffffffffc0201fe4:	40050513          	addi	a0,a0,1024 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0201fe8:	91afe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201fec <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0201fec:	1141                	addi	sp,sp,-16
ffffffffc0201fee:	e022                	sd	s0,0(sp)
ffffffffc0201ff0:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0201ff2:	6508                	ld	a0,8(a0)
ffffffffc0201ff4:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0201ff6:	00a40e63          	beq	s0,a0,ffffffffc0202012 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201ffa:	6118                	ld	a4,0(a0)
ffffffffc0201ffc:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0201ffe:	03000593          	li	a1,48
ffffffffc0202002:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0202004:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202006:	e398                	sd	a4,0(a5)
ffffffffc0202008:	d53ff0ef          	jal	ra,ffffffffc0201d5a <kfree>
    return listelm->next;
ffffffffc020200c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020200e:	fea416e3          	bne	s0,a0,ffffffffc0201ffa <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0202012:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0202014:	6402                	ld	s0,0(sp)
ffffffffc0202016:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0202018:	03000593          	li	a1,48
}
ffffffffc020201c:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc020201e:	bb35                	j	ffffffffc0201d5a <kfree>

ffffffffc0202020 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0202020:	715d                	addi	sp,sp,-80
ffffffffc0202022:	e486                	sd	ra,72(sp)
ffffffffc0202024:	f44e                	sd	s3,40(sp)
ffffffffc0202026:	f052                	sd	s4,32(sp)
ffffffffc0202028:	e0a2                	sd	s0,64(sp)
ffffffffc020202a:	fc26                	sd	s1,56(sp)
ffffffffc020202c:	f84a                	sd	s2,48(sp)
ffffffffc020202e:	ec56                	sd	s5,24(sp)
ffffffffc0202030:	e85a                	sd	s6,16(sp)
ffffffffc0202032:	e45e                	sd	s7,8(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202034:	b87fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202038:	89aa                	mv	s3,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020203a:	b81fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc020203e:	8a2a                	mv	s4,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202040:	03000513          	li	a0,48
ffffffffc0202044:	c5dff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
    if (mm != NULL) {
ffffffffc0202048:	56050863          	beqz	a0,ffffffffc02025b8 <vmm_init+0x598>
    elm->prev = elm->next = elm;
ffffffffc020204c:	e508                	sd	a0,8(a0)
ffffffffc020204e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202050:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202054:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202058:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc020205c:	0000f797          	auipc	a5,0xf
ffffffffc0202060:	5047a783          	lw	a5,1284(a5) # ffffffffc0211560 <swap_init_ok>
ffffffffc0202064:	84aa                	mv	s1,a0
ffffffffc0202066:	e7b9                	bnez	a5,ffffffffc02020b4 <vmm_init+0x94>
        else mm->sm_priv = NULL;
ffffffffc0202068:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc020206c:	03200413          	li	s0,50
ffffffffc0202070:	a811                	j	ffffffffc0202084 <vmm_init+0x64>
        vma->vm_start = vm_start;
ffffffffc0202072:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202074:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202076:	00053c23          	sd	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc020207a:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020207c:	8526                	mv	a0,s1
ffffffffc020207e:	e9fff0ef          	jal	ra,ffffffffc0201f1c <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0202082:	cc05                	beqz	s0,ffffffffc02020ba <vmm_init+0x9a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202084:	03000513          	li	a0,48
ffffffffc0202088:	c19ff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
ffffffffc020208c:	85aa                	mv	a1,a0
ffffffffc020208e:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0202092:	f165                	bnez	a0,ffffffffc0202072 <vmm_init+0x52>
        assert(vma != NULL);
ffffffffc0202094:	00003697          	auipc	a3,0x3
ffffffffc0202098:	5bc68693          	addi	a3,a3,1468 # ffffffffc0205650 <commands+0x1000>
ffffffffc020209c:	00003617          	auipc	a2,0x3
ffffffffc02020a0:	e3c60613          	addi	a2,a2,-452 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02020a4:	0d000593          	li	a1,208
ffffffffc02020a8:	00003517          	auipc	a0,0x3
ffffffffc02020ac:	33850513          	addi	a0,a0,824 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02020b0:	852fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc02020b4:	47d000ef          	jal	ra,ffffffffc0202d30 <swap_init_mm>
ffffffffc02020b8:	bf55                	j	ffffffffc020206c <vmm_init+0x4c>
ffffffffc02020ba:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02020be:	1f900913          	li	s2,505
ffffffffc02020c2:	a819                	j	ffffffffc02020d8 <vmm_init+0xb8>
        vma->vm_start = vm_start;
ffffffffc02020c4:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02020c6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02020c8:	00053c23          	sd	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02020cc:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02020ce:	8526                	mv	a0,s1
ffffffffc02020d0:	e4dff0ef          	jal	ra,ffffffffc0201f1c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02020d4:	03240a63          	beq	s0,s2,ffffffffc0202108 <vmm_init+0xe8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020d8:	03000513          	li	a0,48
ffffffffc02020dc:	bc5ff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
ffffffffc02020e0:	85aa                	mv	a1,a0
ffffffffc02020e2:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc02020e6:	fd79                	bnez	a0,ffffffffc02020c4 <vmm_init+0xa4>
        assert(vma != NULL);
ffffffffc02020e8:	00003697          	auipc	a3,0x3
ffffffffc02020ec:	56868693          	addi	a3,a3,1384 # ffffffffc0205650 <commands+0x1000>
ffffffffc02020f0:	00003617          	auipc	a2,0x3
ffffffffc02020f4:	de860613          	addi	a2,a2,-536 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02020f8:	0d600593          	li	a1,214
ffffffffc02020fc:	00003517          	auipc	a0,0x3
ffffffffc0202100:	2e450513          	addi	a0,a0,740 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202104:	ffffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    return listelm->next;
ffffffffc0202108:	649c                	ld	a5,8(s1)
ffffffffc020210a:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc020210c:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0202110:	2ef48463          	beq	s1,a5,ffffffffc02023f8 <vmm_init+0x3d8>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202114:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202118:	ffe70693          	addi	a3,a4,-2
ffffffffc020211c:	26d61e63          	bne	a2,a3,ffffffffc0202398 <vmm_init+0x378>
ffffffffc0202120:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202124:	26e69a63          	bne	a3,a4,ffffffffc0202398 <vmm_init+0x378>
    for (i = 1; i <= step2; i ++) {
ffffffffc0202128:	0715                	addi	a4,a4,5
ffffffffc020212a:	679c                	ld	a5,8(a5)
ffffffffc020212c:	feb712e3          	bne	a4,a1,ffffffffc0202110 <vmm_init+0xf0>
ffffffffc0202130:	4b1d                	li	s6,7
ffffffffc0202132:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202134:	1f900b93          	li	s7,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202138:	85a2                	mv	a1,s0
ffffffffc020213a:	8526                	mv	a0,s1
ffffffffc020213c:	da1ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
ffffffffc0202140:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202142:	2c050b63          	beqz	a0,ffffffffc0202418 <vmm_init+0x3f8>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0202146:	00140593          	addi	a1,s0,1
ffffffffc020214a:	8526                	mv	a0,s1
ffffffffc020214c:	d91ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
ffffffffc0202150:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc0202152:	2e050363          	beqz	a0,ffffffffc0202438 <vmm_init+0x418>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0202156:	85da                	mv	a1,s6
ffffffffc0202158:	8526                	mv	a0,s1
ffffffffc020215a:	d83ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
        assert(vma3 == NULL);
ffffffffc020215e:	2e051d63          	bnez	a0,ffffffffc0202458 <vmm_init+0x438>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0202162:	00340593          	addi	a1,s0,3
ffffffffc0202166:	8526                	mv	a0,s1
ffffffffc0202168:	d75ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
        assert(vma4 == NULL);
ffffffffc020216c:	30051663          	bnez	a0,ffffffffc0202478 <vmm_init+0x458>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0202170:	00440593          	addi	a1,s0,4
ffffffffc0202174:	8526                	mv	a0,s1
ffffffffc0202176:	d67ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
        assert(vma5 == NULL);
ffffffffc020217a:	30051f63          	bnez	a0,ffffffffc0202498 <vmm_init+0x478>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020217e:	00893783          	ld	a5,8(s2)
ffffffffc0202182:	24879b63          	bne	a5,s0,ffffffffc02023d8 <vmm_init+0x3b8>
ffffffffc0202186:	01093783          	ld	a5,16(s2)
ffffffffc020218a:	25679763          	bne	a5,s6,ffffffffc02023d8 <vmm_init+0x3b8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020218e:	008ab783          	ld	a5,8(s5)
ffffffffc0202192:	22879363          	bne	a5,s0,ffffffffc02023b8 <vmm_init+0x398>
ffffffffc0202196:	010ab783          	ld	a5,16(s5)
ffffffffc020219a:	21679f63          	bne	a5,s6,ffffffffc02023b8 <vmm_init+0x398>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020219e:	0415                	addi	s0,s0,5
ffffffffc02021a0:	0b15                	addi	s6,s6,5
ffffffffc02021a2:	f9741be3          	bne	s0,s7,ffffffffc0202138 <vmm_init+0x118>
ffffffffc02021a6:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02021a8:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02021aa:	85a2                	mv	a1,s0
ffffffffc02021ac:	8526                	mv	a0,s1
ffffffffc02021ae:	d2fff0ef          	jal	ra,ffffffffc0201edc <find_vma>
ffffffffc02021b2:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc02021b6:	c90d                	beqz	a0,ffffffffc02021e8 <vmm_init+0x1c8>
            cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc02021b8:	6914                	ld	a3,16(a0)
ffffffffc02021ba:	6510                	ld	a2,8(a0)
ffffffffc02021bc:	00003517          	auipc	a0,0x3
ffffffffc02021c0:	39450513          	addi	a0,a0,916 # ffffffffc0205550 <commands+0xf00>
ffffffffc02021c4:	ef7fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02021c8:	00003697          	auipc	a3,0x3
ffffffffc02021cc:	3b068693          	addi	a3,a3,944 # ffffffffc0205578 <commands+0xf28>
ffffffffc02021d0:	00003617          	auipc	a2,0x3
ffffffffc02021d4:	d0860613          	addi	a2,a2,-760 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02021d8:	0f800593          	li	a1,248
ffffffffc02021dc:	00003517          	auipc	a0,0x3
ffffffffc02021e0:	20450513          	addi	a0,a0,516 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02021e4:	f1ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc02021e8:	147d                	addi	s0,s0,-1
ffffffffc02021ea:	fd2410e3          	bne	s0,s2,ffffffffc02021aa <vmm_init+0x18a>
ffffffffc02021ee:	a811                	j	ffffffffc0202202 <vmm_init+0x1e2>
    __list_del(listelm->prev, listelm->next);
ffffffffc02021f0:	6118                	ld	a4,0(a0)
ffffffffc02021f2:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc02021f4:	03000593          	li	a1,48
ffffffffc02021f8:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02021fa:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02021fc:	e398                	sd	a4,0(a5)
ffffffffc02021fe:	b5dff0ef          	jal	ra,ffffffffc0201d5a <kfree>
    return listelm->next;
ffffffffc0202202:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list) {
ffffffffc0202204:	fea496e3          	bne	s1,a0,ffffffffc02021f0 <vmm_init+0x1d0>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0202208:	03000593          	li	a1,48
ffffffffc020220c:	8526                	mv	a0,s1
ffffffffc020220e:	b4dff0ef          	jal	ra,ffffffffc0201d5a <kfree>
    }

    mm_destroy(mm);

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202212:	9a9fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202216:	3caa1163          	bne	s4,a0,ffffffffc02025d8 <vmm_init+0x5b8>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc020221a:	00003517          	auipc	a0,0x3
ffffffffc020221e:	39e50513          	addi	a0,a0,926 # ffffffffc02055b8 <commands+0xf68>
ffffffffc0202222:	e99fd0ef          	jal	ra,ffffffffc02000ba <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202226:	995fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc020222a:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020222c:	03000513          	li	a0,48
ffffffffc0202230:	a71ff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
ffffffffc0202234:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0202236:	2a050163          	beqz	a0,ffffffffc02024d8 <vmm_init+0x4b8>
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc020223a:	0000f797          	auipc	a5,0xf
ffffffffc020223e:	3267a783          	lw	a5,806(a5) # ffffffffc0211560 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0202242:	e508                	sd	a0,8(a0)
ffffffffc0202244:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202246:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020224a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020224e:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc0202252:	14079063          	bnez	a5,ffffffffc0202392 <vmm_init+0x372>
        else mm->sm_priv = NULL;
ffffffffc0202256:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();

    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020225a:	0000f917          	auipc	s2,0xf
ffffffffc020225e:	2be93903          	ld	s2,702(s2) # ffffffffc0211518 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0202262:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0202266:	0000f717          	auipc	a4,0xf
ffffffffc020226a:	2c873d23          	sd	s0,730(a4) # ffffffffc0211540 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020226e:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0202272:	24079363          	bnez	a5,ffffffffc02024b8 <vmm_init+0x498>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202276:	03000513          	li	a0,48
ffffffffc020227a:	a27ff0ef          	jal	ra,ffffffffc0201ca0 <kmalloc>
ffffffffc020227e:	8a2a                	mv	s4,a0
    if (vma != NULL) {
ffffffffc0202280:	28050063          	beqz	a0,ffffffffc0202500 <vmm_init+0x4e0>
        vma->vm_end = vm_end;
ffffffffc0202284:	002007b7          	lui	a5,0x200
ffffffffc0202288:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc020228c:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc020228e:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0202290:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0202294:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0202296:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc020229a:	c83ff0ef          	jal	ra,ffffffffc0201f1c <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020229e:	10000593          	li	a1,256
ffffffffc02022a2:	8522                	mv	a0,s0
ffffffffc02022a4:	c39ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
ffffffffc02022a8:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc02022ac:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02022b0:	26aa1863          	bne	s4,a0,ffffffffc0202520 <vmm_init+0x500>
        *(char *)(addr + i) = i;
ffffffffc02022b4:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc02022b8:	0785                	addi	a5,a5,1
ffffffffc02022ba:	fee79de3          	bne	a5,a4,ffffffffc02022b4 <vmm_init+0x294>
        sum += i;
ffffffffc02022be:	6705                	lui	a4,0x1
ffffffffc02022c0:	10000793          	li	a5,256
ffffffffc02022c4:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02022c8:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02022cc:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc02022d0:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc02022d2:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02022d4:	fec79ce3          	bne	a5,a2,ffffffffc02022cc <vmm_init+0x2ac>
    }
    assert(sum == 0);
ffffffffc02022d8:	26071463          	bnez	a4,ffffffffc0202540 <vmm_init+0x520>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02022dc:	4581                	li	a1,0
ffffffffc02022de:	854a                	mv	a0,s2
ffffffffc02022e0:	b65fe0ef          	jal	ra,ffffffffc0200e44 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02022e4:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02022e8:	0000f717          	auipc	a4,0xf
ffffffffc02022ec:	23873703          	ld	a4,568(a4) # ffffffffc0211520 <npage>
    return pa2page(PDE_ADDR(pde));
ffffffffc02022f0:	078a                	slli	a5,a5,0x2
ffffffffc02022f2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02022f4:	26e7f663          	bgeu	a5,a4,ffffffffc0202560 <vmm_init+0x540>
    return &pages[PPN(pa) - nbase];
ffffffffc02022f8:	00004717          	auipc	a4,0x4
ffffffffc02022fc:	ed073703          	ld	a4,-304(a4) # ffffffffc02061c8 <nbase>
ffffffffc0202300:	8f99                	sub	a5,a5,a4
ffffffffc0202302:	00379713          	slli	a4,a5,0x3
ffffffffc0202306:	97ba                	add	a5,a5,a4
ffffffffc0202308:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc020230a:	0000f517          	auipc	a0,0xf
ffffffffc020230e:	21e53503          	ld	a0,542(a0) # ffffffffc0211528 <pages>
ffffffffc0202312:	953e                	add	a0,a0,a5
ffffffffc0202314:	4585                	li	a1,1
ffffffffc0202316:	865fe0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    return listelm->next;
ffffffffc020231a:	6408                	ld	a0,8(s0)

    pgdir[0] = 0;
ffffffffc020231c:	00093023          	sd	zero,0(s2)

    mm->pgdir = NULL;
ffffffffc0202320:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0202324:	00a40e63          	beq	s0,a0,ffffffffc0202340 <vmm_init+0x320>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202328:	6118                	ld	a4,0(a0)
ffffffffc020232a:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc020232c:	03000593          	li	a1,48
ffffffffc0202330:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0202332:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202334:	e398                	sd	a4,0(a5)
ffffffffc0202336:	a25ff0ef          	jal	ra,ffffffffc0201d5a <kfree>
    return listelm->next;
ffffffffc020233a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020233c:	fea416e3          	bne	s0,a0,ffffffffc0202328 <vmm_init+0x308>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0202340:	03000593          	li	a1,48
ffffffffc0202344:	8522                	mv	a0,s0
ffffffffc0202346:	a15ff0ef          	jal	ra,ffffffffc0201d5a <kfree>
    mm_destroy(mm);

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc020234a:	14fd                	addi	s1,s1,-1
    check_mm_struct = NULL;
ffffffffc020234c:	0000f797          	auipc	a5,0xf
ffffffffc0202350:	1e07ba23          	sd	zero,500(a5) # ffffffffc0211540 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202354:	867fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202358:	22a49063          	bne	s1,a0,ffffffffc0202578 <vmm_init+0x558>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc020235c:	00003517          	auipc	a0,0x3
ffffffffc0202360:	2bc50513          	addi	a0,a0,700 # ffffffffc0205618 <commands+0xfc8>
ffffffffc0202364:	d57fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202368:	853fe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc020236c:	19fd                	addi	s3,s3,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020236e:	22a99563          	bne	s3,a0,ffffffffc0202598 <vmm_init+0x578>
}
ffffffffc0202372:	6406                	ld	s0,64(sp)
ffffffffc0202374:	60a6                	ld	ra,72(sp)
ffffffffc0202376:	74e2                	ld	s1,56(sp)
ffffffffc0202378:	7942                	ld	s2,48(sp)
ffffffffc020237a:	79a2                	ld	s3,40(sp)
ffffffffc020237c:	7a02                	ld	s4,32(sp)
ffffffffc020237e:	6ae2                	ld	s5,24(sp)
ffffffffc0202380:	6b42                	ld	s6,16(sp)
ffffffffc0202382:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202384:	00003517          	auipc	a0,0x3
ffffffffc0202388:	2b450513          	addi	a0,a0,692 # ffffffffc0205638 <commands+0xfe8>
}
ffffffffc020238c:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc020238e:	d2dfd06f          	j	ffffffffc02000ba <cprintf>
        if (swap_init_ok) swap_init_mm(mm);//页面置换的初始化
ffffffffc0202392:	19f000ef          	jal	ra,ffffffffc0202d30 <swap_init_mm>
ffffffffc0202396:	b5d1                	j	ffffffffc020225a <vmm_init+0x23a>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202398:	00003697          	auipc	a3,0x3
ffffffffc020239c:	0d068693          	addi	a3,a3,208 # ffffffffc0205468 <commands+0xe18>
ffffffffc02023a0:	00003617          	auipc	a2,0x3
ffffffffc02023a4:	b3860613          	addi	a2,a2,-1224 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02023a8:	0df00593          	li	a1,223
ffffffffc02023ac:	00003517          	auipc	a0,0x3
ffffffffc02023b0:	03450513          	addi	a0,a0,52 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02023b4:	d4ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02023b8:	00003697          	auipc	a3,0x3
ffffffffc02023bc:	16868693          	addi	a3,a3,360 # ffffffffc0205520 <commands+0xed0>
ffffffffc02023c0:	00003617          	auipc	a2,0x3
ffffffffc02023c4:	b1860613          	addi	a2,a2,-1256 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02023c8:	0f000593          	li	a1,240
ffffffffc02023cc:	00003517          	auipc	a0,0x3
ffffffffc02023d0:	01450513          	addi	a0,a0,20 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02023d4:	d2ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02023d8:	00003697          	auipc	a3,0x3
ffffffffc02023dc:	11868693          	addi	a3,a3,280 # ffffffffc02054f0 <commands+0xea0>
ffffffffc02023e0:	00003617          	auipc	a2,0x3
ffffffffc02023e4:	af860613          	addi	a2,a2,-1288 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02023e8:	0ef00593          	li	a1,239
ffffffffc02023ec:	00003517          	auipc	a0,0x3
ffffffffc02023f0:	ff450513          	addi	a0,a0,-12 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02023f4:	d0ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02023f8:	00003697          	auipc	a3,0x3
ffffffffc02023fc:	05868693          	addi	a3,a3,88 # ffffffffc0205450 <commands+0xe00>
ffffffffc0202400:	00003617          	auipc	a2,0x3
ffffffffc0202404:	ad860613          	addi	a2,a2,-1320 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202408:	0dd00593          	li	a1,221
ffffffffc020240c:	00003517          	auipc	a0,0x3
ffffffffc0202410:	fd450513          	addi	a0,a0,-44 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202414:	ceffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma1 != NULL);
ffffffffc0202418:	00003697          	auipc	a3,0x3
ffffffffc020241c:	08868693          	addi	a3,a3,136 # ffffffffc02054a0 <commands+0xe50>
ffffffffc0202420:	00003617          	auipc	a2,0x3
ffffffffc0202424:	ab860613          	addi	a2,a2,-1352 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202428:	0e500593          	li	a1,229
ffffffffc020242c:	00003517          	auipc	a0,0x3
ffffffffc0202430:	fb450513          	addi	a0,a0,-76 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202434:	ccffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma2 != NULL);
ffffffffc0202438:	00003697          	auipc	a3,0x3
ffffffffc020243c:	07868693          	addi	a3,a3,120 # ffffffffc02054b0 <commands+0xe60>
ffffffffc0202440:	00003617          	auipc	a2,0x3
ffffffffc0202444:	a9860613          	addi	a2,a2,-1384 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202448:	0e700593          	li	a1,231
ffffffffc020244c:	00003517          	auipc	a0,0x3
ffffffffc0202450:	f9450513          	addi	a0,a0,-108 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202454:	caffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma3 == NULL);
ffffffffc0202458:	00003697          	auipc	a3,0x3
ffffffffc020245c:	06868693          	addi	a3,a3,104 # ffffffffc02054c0 <commands+0xe70>
ffffffffc0202460:	00003617          	auipc	a2,0x3
ffffffffc0202464:	a7860613          	addi	a2,a2,-1416 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202468:	0e900593          	li	a1,233
ffffffffc020246c:	00003517          	auipc	a0,0x3
ffffffffc0202470:	f7450513          	addi	a0,a0,-140 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202474:	c8ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma4 == NULL);
ffffffffc0202478:	00003697          	auipc	a3,0x3
ffffffffc020247c:	05868693          	addi	a3,a3,88 # ffffffffc02054d0 <commands+0xe80>
ffffffffc0202480:	00003617          	auipc	a2,0x3
ffffffffc0202484:	a5860613          	addi	a2,a2,-1448 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202488:	0eb00593          	li	a1,235
ffffffffc020248c:	00003517          	auipc	a0,0x3
ffffffffc0202490:	f5450513          	addi	a0,a0,-172 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202494:	c6ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma5 == NULL);
ffffffffc0202498:	00003697          	auipc	a3,0x3
ffffffffc020249c:	04868693          	addi	a3,a3,72 # ffffffffc02054e0 <commands+0xe90>
ffffffffc02024a0:	00003617          	auipc	a2,0x3
ffffffffc02024a4:	a3860613          	addi	a2,a2,-1480 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02024a8:	0ed00593          	li	a1,237
ffffffffc02024ac:	00003517          	auipc	a0,0x3
ffffffffc02024b0:	f3450513          	addi	a0,a0,-204 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02024b4:	c4ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02024b8:	00003697          	auipc	a3,0x3
ffffffffc02024bc:	12068693          	addi	a3,a3,288 # ffffffffc02055d8 <commands+0xf88>
ffffffffc02024c0:	00003617          	auipc	a2,0x3
ffffffffc02024c4:	a1860613          	addi	a2,a2,-1512 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02024c8:	10f00593          	li	a1,271
ffffffffc02024cc:	00003517          	auipc	a0,0x3
ffffffffc02024d0:	f1450513          	addi	a0,a0,-236 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02024d4:	c2ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02024d8:	00003697          	auipc	a3,0x3
ffffffffc02024dc:	18868693          	addi	a3,a3,392 # ffffffffc0205660 <commands+0x1010>
ffffffffc02024e0:	00003617          	auipc	a2,0x3
ffffffffc02024e4:	9f860613          	addi	a2,a2,-1544 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02024e8:	10c00593          	li	a1,268
ffffffffc02024ec:	00003517          	auipc	a0,0x3
ffffffffc02024f0:	ef450513          	addi	a0,a0,-268 # ffffffffc02053e0 <commands+0xd90>
    check_mm_struct = mm_create();
ffffffffc02024f4:	0000f797          	auipc	a5,0xf
ffffffffc02024f8:	0407b623          	sd	zero,76(a5) # ffffffffc0211540 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc02024fc:	c07fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(vma != NULL);
ffffffffc0202500:	00003697          	auipc	a3,0x3
ffffffffc0202504:	15068693          	addi	a3,a3,336 # ffffffffc0205650 <commands+0x1000>
ffffffffc0202508:	00003617          	auipc	a2,0x3
ffffffffc020250c:	9d060613          	addi	a2,a2,-1584 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202510:	11300593          	li	a1,275
ffffffffc0202514:	00003517          	auipc	a0,0x3
ffffffffc0202518:	ecc50513          	addi	a0,a0,-308 # ffffffffc02053e0 <commands+0xd90>
ffffffffc020251c:	be7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0202520:	00003697          	auipc	a3,0x3
ffffffffc0202524:	0c868693          	addi	a3,a3,200 # ffffffffc02055e8 <commands+0xf98>
ffffffffc0202528:	00003617          	auipc	a2,0x3
ffffffffc020252c:	9b060613          	addi	a2,a2,-1616 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202530:	11800593          	li	a1,280
ffffffffc0202534:	00003517          	auipc	a0,0x3
ffffffffc0202538:	eac50513          	addi	a0,a0,-340 # ffffffffc02053e0 <commands+0xd90>
ffffffffc020253c:	bc7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(sum == 0);
ffffffffc0202540:	00003697          	auipc	a3,0x3
ffffffffc0202544:	0c868693          	addi	a3,a3,200 # ffffffffc0205608 <commands+0xfb8>
ffffffffc0202548:	00003617          	auipc	a2,0x3
ffffffffc020254c:	99060613          	addi	a2,a2,-1648 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202550:	12200593          	li	a1,290
ffffffffc0202554:	00003517          	auipc	a0,0x3
ffffffffc0202558:	e8c50513          	addi	a0,a0,-372 # ffffffffc02053e0 <commands+0xd90>
ffffffffc020255c:	ba7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202560:	00002617          	auipc	a2,0x2
ffffffffc0202564:	7f860613          	addi	a2,a2,2040 # ffffffffc0204d58 <commands+0x708>
ffffffffc0202568:	06c00593          	li	a1,108
ffffffffc020256c:	00003517          	auipc	a0,0x3
ffffffffc0202570:	80c50513          	addi	a0,a0,-2036 # ffffffffc0204d78 <commands+0x728>
ffffffffc0202574:	b8ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202578:	00003697          	auipc	a3,0x3
ffffffffc020257c:	01868693          	addi	a3,a3,24 # ffffffffc0205590 <commands+0xf40>
ffffffffc0202580:	00003617          	auipc	a2,0x3
ffffffffc0202584:	95860613          	addi	a2,a2,-1704 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202588:	13000593          	li	a1,304
ffffffffc020258c:	00003517          	auipc	a0,0x3
ffffffffc0202590:	e5450513          	addi	a0,a0,-428 # ffffffffc02053e0 <commands+0xd90>
ffffffffc0202594:	b6ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202598:	00003697          	auipc	a3,0x3
ffffffffc020259c:	ff868693          	addi	a3,a3,-8 # ffffffffc0205590 <commands+0xf40>
ffffffffc02025a0:	00003617          	auipc	a2,0x3
ffffffffc02025a4:	93860613          	addi	a2,a2,-1736 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02025a8:	0bf00593          	li	a1,191
ffffffffc02025ac:	00003517          	auipc	a0,0x3
ffffffffc02025b0:	e3450513          	addi	a0,a0,-460 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02025b4:	b4ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(mm != NULL);
ffffffffc02025b8:	00003697          	auipc	a3,0x3
ffffffffc02025bc:	0c068693          	addi	a3,a3,192 # ffffffffc0205678 <commands+0x1028>
ffffffffc02025c0:	00003617          	auipc	a2,0x3
ffffffffc02025c4:	91860613          	addi	a2,a2,-1768 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02025c8:	0c900593          	li	a1,201
ffffffffc02025cc:	00003517          	auipc	a0,0x3
ffffffffc02025d0:	e1450513          	addi	a0,a0,-492 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02025d4:	b2ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02025d8:	00003697          	auipc	a3,0x3
ffffffffc02025dc:	fb868693          	addi	a3,a3,-72 # ffffffffc0205590 <commands+0xf40>
ffffffffc02025e0:	00003617          	auipc	a2,0x3
ffffffffc02025e4:	8f860613          	addi	a2,a2,-1800 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02025e8:	0fd00593          	li	a1,253
ffffffffc02025ec:	00003517          	auipc	a0,0x3
ffffffffc02025f0:	df450513          	addi	a0,a0,-524 # ffffffffc02053e0 <commands+0xd90>
ffffffffc02025f4:	b0ffd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02025f8 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02025f8:	7179                	addi	sp,sp,-48
    // }

    //addr: 访问出错的虚拟地址
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02025fa:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02025fc:	f022                	sd	s0,32(sp)
ffffffffc02025fe:	ec26                	sd	s1,24(sp)
ffffffffc0202600:	f406                	sd	ra,40(sp)
ffffffffc0202602:	e84a                	sd	s2,16(sp)
ffffffffc0202604:	8432                	mv	s0,a2
ffffffffc0202606:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0202608:	8d5ff0ef          	jal	ra,ffffffffc0201edc <find_vma>
    //在mm_struct里判断这个虚拟地址是否可用
    pgfault_num++;
ffffffffc020260c:	0000f797          	auipc	a5,0xf
ffffffffc0202610:	f3c7a783          	lw	a5,-196(a5) # ffffffffc0211548 <pgfault_num>
ffffffffc0202614:	2785                	addiw	a5,a5,1
ffffffffc0202616:	0000f717          	auipc	a4,0xf
ffffffffc020261a:	f2f72923          	sw	a5,-206(a4) # ffffffffc0211548 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc020261e:	c159                	beqz	a0,ffffffffc02026a4 <do_pgfault+0xac>
ffffffffc0202620:	651c                	ld	a5,8(a0)
ffffffffc0202622:	08f46163          	bltu	s0,a5,ffffffffc02026a4 <do_pgfault+0xac>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0202626:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0202628:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020262a:	8b89                	andi	a5,a5,2
ffffffffc020262c:	ebb1                	bnez	a5,ffffffffc0202680 <do_pgfault+0x88>
        perm |= (PTE_R | PTE_W);
    }
    // perm &= ~PTE_R;

    addr = ROUNDDOWN(addr, PGSIZE);//按照页面大小把地址对齐
ffffffffc020262e:	75fd                	lui	a1,0xfffff
    *   mm->pgdir : the PDT of these vma
    *
    */


    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0202630:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);//按照页面大小把地址对齐
ffffffffc0202632:	8c6d                	and	s0,s0,a1
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0202634:	85a2                	mv	a1,s0
ffffffffc0202636:	4605                	li	a2,1
ffffffffc0202638:	dbcfe0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
ffffffffc020263c:	610c                	ld	a1,0(a0)
ffffffffc020263e:	c1b9                	beqz	a1,ffffffffc0202684 <do_pgfault+0x8c>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0202640:	0000f797          	auipc	a5,0xf
ffffffffc0202644:	f207a783          	lw	a5,-224(a5) # ffffffffc0211560 <swap_init_ok>
ffffffffc0202648:	c7bd                	beqz	a5,ffffffffc02026b6 <do_pgfault+0xbe>
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.

            swap_in(mm,addr,&page);
ffffffffc020264a:	85a2                	mv	a1,s0
ffffffffc020264c:	0030                	addi	a2,sp,8
ffffffffc020264e:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0202650:	e402                	sd	zero,8(sp)
            swap_in(mm,addr,&page);
ffffffffc0202652:	00b000ef          	jal	ra,ffffffffc0202e5c <swap_in>
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc0202656:	65a2                	ld	a1,8(sp)
ffffffffc0202658:	6c88                	ld	a0,24(s1)
ffffffffc020265a:	86ca                	mv	a3,s2
ffffffffc020265c:	8622                	mv	a2,s0
ffffffffc020265e:	881fe0ef          	jal	ra,ffffffffc0200ede <page_insert>
            swap_map_swappable(mm,addr,page,1);
ffffffffc0202662:	6622                	ld	a2,8(sp)
ffffffffc0202664:	4685                	li	a3,1
ffffffffc0202666:	85a2                	mv	a1,s0
ffffffffc0202668:	8526                	mv	a0,s1
ffffffffc020266a:	6d2000ef          	jal	ra,ffffffffc0202d3c <swap_map_swappable>

            page->pra_vaddr = addr;
ffffffffc020266e:	67a2                	ld	a5,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc0202670:	4501                	li	a0,0
            page->pra_vaddr = addr;
ffffffffc0202672:	e3a0                	sd	s0,64(a5)
failed:
    return ret;
}
ffffffffc0202674:	70a2                	ld	ra,40(sp)
ffffffffc0202676:	7402                	ld	s0,32(sp)
ffffffffc0202678:	64e2                	ld	s1,24(sp)
ffffffffc020267a:	6942                	ld	s2,16(sp)
ffffffffc020267c:	6145                	addi	sp,sp,48
ffffffffc020267e:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc0202680:	4959                	li	s2,22
ffffffffc0202682:	b775                	j	ffffffffc020262e <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0202684:	6c88                	ld	a0,24(s1)
ffffffffc0202686:	864a                	mv	a2,s2
ffffffffc0202688:	85a2                	mv	a1,s0
ffffffffc020268a:	d5eff0ef          	jal	ra,ffffffffc0201be8 <pgdir_alloc_page>
ffffffffc020268e:	87aa                	mv	a5,a0
   ret = 0;
ffffffffc0202690:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0202692:	f3ed                	bnez	a5,ffffffffc0202674 <do_pgfault+0x7c>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0202694:	00003517          	auipc	a0,0x3
ffffffffc0202698:	02450513          	addi	a0,a0,36 # ffffffffc02056b8 <commands+0x1068>
ffffffffc020269c:	a1ffd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM;
ffffffffc02026a0:	5571                	li	a0,-4
            goto failed;
ffffffffc02026a2:	bfc9                	j	ffffffffc0202674 <do_pgfault+0x7c>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02026a4:	85a2                	mv	a1,s0
ffffffffc02026a6:	00003517          	auipc	a0,0x3
ffffffffc02026aa:	fe250513          	addi	a0,a0,-30 # ffffffffc0205688 <commands+0x1038>
ffffffffc02026ae:	a0dfd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    int ret = -E_INVAL;
ffffffffc02026b2:	5575                	li	a0,-3
        goto failed;
ffffffffc02026b4:	b7c1                	j	ffffffffc0202674 <do_pgfault+0x7c>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02026b6:	00003517          	auipc	a0,0x3
ffffffffc02026ba:	02a50513          	addi	a0,a0,42 # ffffffffc02056e0 <commands+0x1090>
ffffffffc02026be:	9fdfd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM;
ffffffffc02026c2:	5571                	li	a0,-4
            goto failed;
ffffffffc02026c4:	bf45                	j	ffffffffc0202674 <do_pgfault+0x7c>

ffffffffc02026c6 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02026c6:	7135                	addi	sp,sp,-160
ffffffffc02026c8:	ed06                	sd	ra,152(sp)
ffffffffc02026ca:	e922                	sd	s0,144(sp)
ffffffffc02026cc:	e526                	sd	s1,136(sp)
ffffffffc02026ce:	e14a                	sd	s2,128(sp)
ffffffffc02026d0:	fcce                	sd	s3,120(sp)
ffffffffc02026d2:	f8d2                	sd	s4,112(sp)
ffffffffc02026d4:	f4d6                	sd	s5,104(sp)
ffffffffc02026d6:	f0da                	sd	s6,96(sp)
ffffffffc02026d8:	ecde                	sd	s7,88(sp)
ffffffffc02026da:	e8e2                	sd	s8,80(sp)
ffffffffc02026dc:	e4e6                	sd	s9,72(sp)
ffffffffc02026de:	e0ea                	sd	s10,64(sp)
ffffffffc02026e0:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc02026e2:	63e010ef          	jal	ra,ffffffffc0203d20 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02026e6:	0000f697          	auipc	a3,0xf
ffffffffc02026ea:	e6a6b683          	ld	a3,-406(a3) # ffffffffc0211550 <max_swap_offset>
ffffffffc02026ee:	010007b7          	lui	a5,0x1000
ffffffffc02026f2:	ff968713          	addi	a4,a3,-7
ffffffffc02026f6:	17e1                	addi	a5,a5,-8
ffffffffc02026f8:	3ee7e063          	bltu	a5,a4,ffffffffc0202ad8 <swap_init+0x412>
          max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc02026fc:	00008797          	auipc	a5,0x8
ffffffffc0202700:	90478793          	addi	a5,a5,-1788 # ffffffffc020a000 <swap_manager_clock>
    // sm = &swap_manager_fifo;
    // sm = &swap_manager_lru;
     int r = sm->init();
ffffffffc0202704:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc0202706:	0000fb17          	auipc	s6,0xf
ffffffffc020270a:	e52b0b13          	addi	s6,s6,-430 # ffffffffc0211558 <sm>
ffffffffc020270e:	00fb3023          	sd	a5,0(s6)
     int r = sm->init();
ffffffffc0202712:	9702                	jalr	a4
ffffffffc0202714:	89aa                	mv	s3,a0
     
     if (r == 0)
ffffffffc0202716:	c10d                	beqz	a0,ffffffffc0202738 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0202718:	60ea                	ld	ra,152(sp)
ffffffffc020271a:	644a                	ld	s0,144(sp)
ffffffffc020271c:	64aa                	ld	s1,136(sp)
ffffffffc020271e:	690a                	ld	s2,128(sp)
ffffffffc0202720:	7a46                	ld	s4,112(sp)
ffffffffc0202722:	7aa6                	ld	s5,104(sp)
ffffffffc0202724:	7b06                	ld	s6,96(sp)
ffffffffc0202726:	6be6                	ld	s7,88(sp)
ffffffffc0202728:	6c46                	ld	s8,80(sp)
ffffffffc020272a:	6ca6                	ld	s9,72(sp)
ffffffffc020272c:	6d06                	ld	s10,64(sp)
ffffffffc020272e:	7de2                	ld	s11,56(sp)
ffffffffc0202730:	854e                	mv	a0,s3
ffffffffc0202732:	79e6                	ld	s3,120(sp)
ffffffffc0202734:	610d                	addi	sp,sp,160
ffffffffc0202736:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202738:	000b3783          	ld	a5,0(s6)
ffffffffc020273c:	00003517          	auipc	a0,0x3
ffffffffc0202740:	ffc50513          	addi	a0,a0,-4 # ffffffffc0205738 <commands+0x10e8>
ffffffffc0202744:	0000f497          	auipc	s1,0xf
ffffffffc0202748:	99c48493          	addi	s1,s1,-1636 # ffffffffc02110e0 <free_area>
ffffffffc020274c:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc020274e:	4785                	li	a5,1
ffffffffc0202750:	0000f717          	auipc	a4,0xf
ffffffffc0202754:	e0f72823          	sw	a5,-496(a4) # ffffffffc0211560 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202758:	963fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc020275c:	649c                	ld	a5,8(s1)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc020275e:	4401                	li	s0,0
ffffffffc0202760:	4d01                	li	s10,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202762:	2c978163          	beq	a5,s1,ffffffffc0202a24 <swap_init+0x35e>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202766:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020276a:	8b09                	andi	a4,a4,2
ffffffffc020276c:	2a070e63          	beqz	a4,ffffffffc0202a28 <swap_init+0x362>
        count ++, total += p->property;
ffffffffc0202770:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202774:	679c                	ld	a5,8(a5)
ffffffffc0202776:	2d05                	addiw	s10,s10,1
ffffffffc0202778:	9c39                	addw	s0,s0,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020277a:	fe9796e3          	bne	a5,s1,ffffffffc0202766 <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc020277e:	8922                	mv	s2,s0
ffffffffc0202780:	c3afe0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc0202784:	47251663          	bne	a0,s2,ffffffffc0202bf0 <swap_init+0x52a>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202788:	8622                	mv	a2,s0
ffffffffc020278a:	85ea                	mv	a1,s10
ffffffffc020278c:	00003517          	auipc	a0,0x3
ffffffffc0202790:	ff450513          	addi	a0,a0,-12 # ffffffffc0205780 <commands+0x1130>
ffffffffc0202794:	927fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202798:	eceff0ef          	jal	ra,ffffffffc0201e66 <mm_create>
ffffffffc020279c:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc020279e:	52050963          	beqz	a0,ffffffffc0202cd0 <swap_init+0x60a>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc02027a2:	0000f797          	auipc	a5,0xf
ffffffffc02027a6:	d9e78793          	addi	a5,a5,-610 # ffffffffc0211540 <check_mm_struct>
ffffffffc02027aa:	6398                	ld	a4,0(a5)
ffffffffc02027ac:	54071263          	bnez	a4,ffffffffc0202cf0 <swap_init+0x62a>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02027b0:	0000fb97          	auipc	s7,0xf
ffffffffc02027b4:	d68bbb83          	ld	s7,-664(s7) # ffffffffc0211518 <boot_pgdir>
     assert(pgdir[0] == 0);
ffffffffc02027b8:	000bb703          	ld	a4,0(s7)
     check_mm_struct = mm;
ffffffffc02027bc:	e388                	sd	a0,0(a5)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02027be:	01753c23          	sd	s7,24(a0)
     assert(pgdir[0] == 0);
ffffffffc02027c2:	3c071763          	bnez	a4,ffffffffc0202b90 <swap_init+0x4ca>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02027c6:	6599                	lui	a1,0x6
ffffffffc02027c8:	460d                	li	a2,3
ffffffffc02027ca:	6505                	lui	a0,0x1
ffffffffc02027cc:	ee2ff0ef          	jal	ra,ffffffffc0201eae <vma_create>
ffffffffc02027d0:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02027d2:	3c050f63          	beqz	a0,ffffffffc0202bb0 <swap_init+0x4ea>

     insert_vma_struct(mm, vma);
ffffffffc02027d6:	8556                	mv	a0,s5
ffffffffc02027d8:	f44ff0ef          	jal	ra,ffffffffc0201f1c <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02027dc:	00003517          	auipc	a0,0x3
ffffffffc02027e0:	fe450513          	addi	a0,a0,-28 # ffffffffc02057c0 <commands+0x1170>
ffffffffc02027e4:	8d7fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02027e8:	018ab503          	ld	a0,24(s5)
ffffffffc02027ec:	4605                	li	a2,1
ffffffffc02027ee:	6585                	lui	a1,0x1
ffffffffc02027f0:	c04fe0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02027f4:	3c050e63          	beqz	a0,ffffffffc0202bd0 <swap_init+0x50a>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02027f8:	00003517          	auipc	a0,0x3
ffffffffc02027fc:	01850513          	addi	a0,a0,24 # ffffffffc0205810 <commands+0x11c0>
ffffffffc0202800:	0000f917          	auipc	s2,0xf
ffffffffc0202804:	86090913          	addi	s2,s2,-1952 # ffffffffc0211060 <check_rp>
ffffffffc0202808:	8b3fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020280c:	0000fa17          	auipc	s4,0xf
ffffffffc0202810:	874a0a13          	addi	s4,s4,-1932 # ffffffffc0211080 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202814:	8c4a                	mv	s8,s2
          check_rp[i] = alloc_page();
ffffffffc0202816:	4505                	li	a0,1
ffffffffc0202818:	ad0fe0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020281c:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0202820:	28050c63          	beqz	a0,ffffffffc0202ab8 <swap_init+0x3f2>
ffffffffc0202824:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202826:	8b89                	andi	a5,a5,2
ffffffffc0202828:	26079863          	bnez	a5,ffffffffc0202a98 <swap_init+0x3d2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020282c:	0c21                	addi	s8,s8,8
ffffffffc020282e:	ff4c14e3          	bne	s8,s4,ffffffffc0202816 <swap_init+0x150>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202832:	609c                	ld	a5,0(s1)
ffffffffc0202834:	0084bd83          	ld	s11,8(s1)
    elm->prev = elm->next = elm;
ffffffffc0202838:	e084                	sd	s1,0(s1)
ffffffffc020283a:	f03e                	sd	a5,32(sp)
     list_init(&free_list);
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
ffffffffc020283c:	489c                	lw	a5,16(s1)
ffffffffc020283e:	e484                	sd	s1,8(s1)
     nr_free = 0;
ffffffffc0202840:	0000fc17          	auipc	s8,0xf
ffffffffc0202844:	820c0c13          	addi	s8,s8,-2016 # ffffffffc0211060 <check_rp>
     unsigned int nr_free_store = nr_free;
ffffffffc0202848:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc020284a:	0000f797          	auipc	a5,0xf
ffffffffc020284e:	8a07a323          	sw	zero,-1882(a5) # ffffffffc02110f0 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202852:	000c3503          	ld	a0,0(s8)
ffffffffc0202856:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202858:	0c21                	addi	s8,s8,8
        free_pages(check_rp[i],1);
ffffffffc020285a:	b20fe0ef          	jal	ra,ffffffffc0200b7a <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020285e:	ff4c1ae3          	bne	s8,s4,ffffffffc0202852 <swap_init+0x18c>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202862:	0104ac03          	lw	s8,16(s1)
ffffffffc0202866:	4791                	li	a5,4
ffffffffc0202868:	4afc1463          	bne	s8,a5,ffffffffc0202d10 <swap_init+0x64a>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc020286c:	00003517          	auipc	a0,0x3
ffffffffc0202870:	02c50513          	addi	a0,a0,44 # ffffffffc0205898 <commands+0x1248>
ffffffffc0202874:	847fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202878:	6605                	lui	a2,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc020287a:	0000f797          	auipc	a5,0xf
ffffffffc020287e:	cc07a723          	sw	zero,-818(a5) # ffffffffc0211548 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202882:	4529                	li	a0,10
ffffffffc0202884:	00a60023          	sb	a0,0(a2) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202888:	0000f597          	auipc	a1,0xf
ffffffffc020288c:	cc05a583          	lw	a1,-832(a1) # ffffffffc0211548 <pgfault_num>
ffffffffc0202890:	4805                	li	a6,1
ffffffffc0202892:	0000f797          	auipc	a5,0xf
ffffffffc0202896:	cb678793          	addi	a5,a5,-842 # ffffffffc0211548 <pgfault_num>
ffffffffc020289a:	3f059b63          	bne	a1,a6,ffffffffc0202c90 <swap_init+0x5ca>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc020289e:	00a60823          	sb	a0,16(a2)
     assert(pgfault_num==1);
ffffffffc02028a2:	4390                	lw	a2,0(a5)
ffffffffc02028a4:	2601                	sext.w	a2,a2
ffffffffc02028a6:	40b61563          	bne	a2,a1,ffffffffc0202cb0 <swap_init+0x5ea>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02028aa:	6589                	lui	a1,0x2
ffffffffc02028ac:	452d                	li	a0,11
ffffffffc02028ae:	00a58023          	sb	a0,0(a1) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc02028b2:	4390                	lw	a2,0(a5)
ffffffffc02028b4:	4809                	li	a6,2
ffffffffc02028b6:	2601                	sext.w	a2,a2
ffffffffc02028b8:	35061c63          	bne	a2,a6,ffffffffc0202c10 <swap_init+0x54a>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02028bc:	00a58823          	sb	a0,16(a1)
     assert(pgfault_num==2);
ffffffffc02028c0:	438c                	lw	a1,0(a5)
ffffffffc02028c2:	2581                	sext.w	a1,a1
ffffffffc02028c4:	36c59663          	bne	a1,a2,ffffffffc0202c30 <swap_init+0x56a>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02028c8:	658d                	lui	a1,0x3
ffffffffc02028ca:	4531                	li	a0,12
ffffffffc02028cc:	00a58023          	sb	a0,0(a1) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc02028d0:	4390                	lw	a2,0(a5)
ffffffffc02028d2:	480d                	li	a6,3
ffffffffc02028d4:	2601                	sext.w	a2,a2
ffffffffc02028d6:	37061d63          	bne	a2,a6,ffffffffc0202c50 <swap_init+0x58a>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02028da:	00a58823          	sb	a0,16(a1)
     assert(pgfault_num==3);
ffffffffc02028de:	438c                	lw	a1,0(a5)
ffffffffc02028e0:	2581                	sext.w	a1,a1
ffffffffc02028e2:	38c59763          	bne	a1,a2,ffffffffc0202c70 <swap_init+0x5aa>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02028e6:	6591                	lui	a1,0x4
ffffffffc02028e8:	4535                	li	a0,13
ffffffffc02028ea:	00a58023          	sb	a0,0(a1) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc02028ee:	4390                	lw	a2,0(a5)
ffffffffc02028f0:	2601                	sext.w	a2,a2
ffffffffc02028f2:	21861f63          	bne	a2,s8,ffffffffc0202b10 <swap_init+0x44a>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02028f6:	00a58823          	sb	a0,16(a1)
     assert(pgfault_num==4);
ffffffffc02028fa:	439c                	lw	a5,0(a5)
ffffffffc02028fc:	2781                	sext.w	a5,a5
ffffffffc02028fe:	22c79963          	bne	a5,a2,ffffffffc0202b30 <swap_init+0x46a>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202902:	489c                	lw	a5,16(s1)
ffffffffc0202904:	24079663          	bnez	a5,ffffffffc0202b50 <swap_init+0x48a>
ffffffffc0202908:	0000e797          	auipc	a5,0xe
ffffffffc020290c:	77878793          	addi	a5,a5,1912 # ffffffffc0211080 <swap_in_seq_no>
ffffffffc0202910:	0000e617          	auipc	a2,0xe
ffffffffc0202914:	79860613          	addi	a2,a2,1944 # ffffffffc02110a8 <swap_out_seq_no>
ffffffffc0202918:	0000e517          	auipc	a0,0xe
ffffffffc020291c:	79050513          	addi	a0,a0,1936 # ffffffffc02110a8 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202920:	55fd                	li	a1,-1
ffffffffc0202922:	c38c                	sw	a1,0(a5)
ffffffffc0202924:	c20c                	sw	a1,0(a2)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202926:	0791                	addi	a5,a5,4
ffffffffc0202928:	0611                	addi	a2,a2,4
ffffffffc020292a:	fef51ce3          	bne	a0,a5,ffffffffc0202922 <swap_init+0x25c>
ffffffffc020292e:	0000e817          	auipc	a6,0xe
ffffffffc0202932:	71280813          	addi	a6,a6,1810 # ffffffffc0211040 <check_ptep>
ffffffffc0202936:	0000e897          	auipc	a7,0xe
ffffffffc020293a:	72a88893          	addi	a7,a7,1834 # ffffffffc0211060 <check_rp>
ffffffffc020293e:	6585                	lui	a1,0x1
    return &pages[PPN(pa) - nbase];
ffffffffc0202940:	0000fc97          	auipc	s9,0xf
ffffffffc0202944:	be8c8c93          	addi	s9,s9,-1048 # ffffffffc0211528 <pages>
ffffffffc0202948:	00004c17          	auipc	s8,0x4
ffffffffc020294c:	880c0c13          	addi	s8,s8,-1920 # ffffffffc02061c8 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0202950:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202954:	4601                	li	a2,0
ffffffffc0202956:	855e                	mv	a0,s7
ffffffffc0202958:	ec46                	sd	a7,24(sp)
ffffffffc020295a:	e82e                	sd	a1,16(sp)
         check_ptep[i]=0;
ffffffffc020295c:	e442                	sd	a6,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020295e:	a96fe0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
ffffffffc0202962:	6822                	ld	a6,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202964:	65c2                	ld	a1,16(sp)
ffffffffc0202966:	68e2                	ld	a7,24(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202968:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL);
ffffffffc020296c:	0000f317          	auipc	t1,0xf
ffffffffc0202970:	bb430313          	addi	t1,t1,-1100 # ffffffffc0211520 <npage>
ffffffffc0202974:	16050e63          	beqz	a0,ffffffffc0202af0 <swap_init+0x42a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202978:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020297a:	0017f613          	andi	a2,a5,1
ffffffffc020297e:	0e060563          	beqz	a2,ffffffffc0202a68 <swap_init+0x3a2>
    if (PPN(pa) >= npage) {
ffffffffc0202982:	00033603          	ld	a2,0(t1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202986:	078a                	slli	a5,a5,0x2
ffffffffc0202988:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020298a:	0ec7fb63          	bgeu	a5,a2,ffffffffc0202a80 <swap_init+0x3ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020298e:	000c3603          	ld	a2,0(s8)
ffffffffc0202992:	000cb503          	ld	a0,0(s9)
ffffffffc0202996:	0008bf03          	ld	t5,0(a7)
ffffffffc020299a:	8f91                	sub	a5,a5,a2
ffffffffc020299c:	00379613          	slli	a2,a5,0x3
ffffffffc02029a0:	97b2                	add	a5,a5,a2
ffffffffc02029a2:	078e                	slli	a5,a5,0x3
ffffffffc02029a4:	97aa                	add	a5,a5,a0
ffffffffc02029a6:	0aff1163          	bne	t5,a5,ffffffffc0202a48 <swap_init+0x382>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02029aa:	6785                	lui	a5,0x1
ffffffffc02029ac:	95be                	add	a1,a1,a5
ffffffffc02029ae:	6795                	lui	a5,0x5
ffffffffc02029b0:	0821                	addi	a6,a6,8
ffffffffc02029b2:	08a1                	addi	a7,a7,8
ffffffffc02029b4:	f8f59ee3          	bne	a1,a5,ffffffffc0202950 <swap_init+0x28a>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc02029b8:	00003517          	auipc	a0,0x3
ffffffffc02029bc:	f9850513          	addi	a0,a0,-104 # ffffffffc0205950 <commands+0x1300>
ffffffffc02029c0:	efafd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    int ret = sm->check_swap();
ffffffffc02029c4:	000b3783          	ld	a5,0(s6)
ffffffffc02029c8:	7f9c                	ld	a5,56(a5)
ffffffffc02029ca:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
    ret=check_content_access();
     assert(ret==0);
ffffffffc02029cc:	1a051263          	bnez	a0,ffffffffc0202b70 <swap_init+0x4aa>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02029d0:	00093503          	ld	a0,0(s2)
ffffffffc02029d4:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02029d6:	0921                	addi	s2,s2,8
         free_pages(check_rp[i],1);
ffffffffc02029d8:	9a2fe0ef          	jal	ra,ffffffffc0200b7a <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02029dc:	ff491ae3          	bne	s2,s4,ffffffffc02029d0 <swap_init+0x30a>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc02029e0:	8556                	mv	a0,s5
ffffffffc02029e2:	e0aff0ef          	jal	ra,ffffffffc0201fec <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc02029e6:	77a2                	ld	a5,40(sp)
     free_list = free_list_store;
ffffffffc02029e8:	01b4b423          	sd	s11,8(s1)
     nr_free = nr_free_store;
ffffffffc02029ec:	c89c                	sw	a5,16(s1)
     free_list = free_list_store;
ffffffffc02029ee:	7782                	ld	a5,32(sp)
ffffffffc02029f0:	e09c                	sd	a5,0(s1)

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02029f2:	009d8a63          	beq	s11,s1,ffffffffc0202a06 <swap_init+0x340>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc02029f6:	ff8da783          	lw	a5,-8(s11)
    return listelm->next;
ffffffffc02029fa:	008dbd83          	ld	s11,8(s11)
ffffffffc02029fe:	3d7d                	addiw	s10,s10,-1
ffffffffc0202a00:	9c1d                	subw	s0,s0,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a02:	fe9d9ae3          	bne	s11,s1,ffffffffc02029f6 <swap_init+0x330>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc0202a06:	8622                	mv	a2,s0
ffffffffc0202a08:	85ea                	mv	a1,s10
ffffffffc0202a0a:	00003517          	auipc	a0,0x3
ffffffffc0202a0e:	f7650513          	addi	a0,a0,-138 # ffffffffc0205980 <commands+0x1330>
ffffffffc0202a12:	ea8fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0202a16:	00003517          	auipc	a0,0x3
ffffffffc0202a1a:	f8a50513          	addi	a0,a0,-118 # ffffffffc02059a0 <commands+0x1350>
ffffffffc0202a1e:	e9cfd0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0202a22:	b9dd                	j	ffffffffc0202718 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a24:	4901                	li	s2,0
ffffffffc0202a26:	bba9                	j	ffffffffc0202780 <swap_init+0xba>
        assert(PageProperty(p));
ffffffffc0202a28:	00003697          	auipc	a3,0x3
ffffffffc0202a2c:	d2868693          	addi	a3,a3,-728 # ffffffffc0205750 <commands+0x1100>
ffffffffc0202a30:	00002617          	auipc	a2,0x2
ffffffffc0202a34:	4a860613          	addi	a2,a2,1192 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202a38:	0c100593          	li	a1,193
ffffffffc0202a3c:	00003517          	auipc	a0,0x3
ffffffffc0202a40:	cec50513          	addi	a0,a0,-788 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202a44:	ebefd0ef          	jal	ra,ffffffffc0200102 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202a48:	00003697          	auipc	a3,0x3
ffffffffc0202a4c:	ee068693          	addi	a3,a3,-288 # ffffffffc0205928 <commands+0x12d8>
ffffffffc0202a50:	00002617          	auipc	a2,0x2
ffffffffc0202a54:	48860613          	addi	a2,a2,1160 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202a58:	10100593          	li	a1,257
ffffffffc0202a5c:	00003517          	auipc	a0,0x3
ffffffffc0202a60:	ccc50513          	addi	a0,a0,-820 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202a64:	e9efd0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202a68:	00002617          	auipc	a2,0x2
ffffffffc0202a6c:	32060613          	addi	a2,a2,800 # ffffffffc0204d88 <commands+0x738>
ffffffffc0202a70:	07700593          	li	a1,119
ffffffffc0202a74:	00002517          	auipc	a0,0x2
ffffffffc0202a78:	30450513          	addi	a0,a0,772 # ffffffffc0204d78 <commands+0x728>
ffffffffc0202a7c:	e86fd0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202a80:	00002617          	auipc	a2,0x2
ffffffffc0202a84:	2d860613          	addi	a2,a2,728 # ffffffffc0204d58 <commands+0x708>
ffffffffc0202a88:	06c00593          	li	a1,108
ffffffffc0202a8c:	00002517          	auipc	a0,0x2
ffffffffc0202a90:	2ec50513          	addi	a0,a0,748 # ffffffffc0204d78 <commands+0x728>
ffffffffc0202a94:	e6efd0ef          	jal	ra,ffffffffc0200102 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202a98:	00003697          	auipc	a3,0x3
ffffffffc0202a9c:	db868693          	addi	a3,a3,-584 # ffffffffc0205850 <commands+0x1200>
ffffffffc0202aa0:	00002617          	auipc	a2,0x2
ffffffffc0202aa4:	43860613          	addi	a2,a2,1080 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202aa8:	0e200593          	li	a1,226
ffffffffc0202aac:	00003517          	auipc	a0,0x3
ffffffffc0202ab0:	c7c50513          	addi	a0,a0,-900 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202ab4:	e4efd0ef          	jal	ra,ffffffffc0200102 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202ab8:	00003697          	auipc	a3,0x3
ffffffffc0202abc:	d8068693          	addi	a3,a3,-640 # ffffffffc0205838 <commands+0x11e8>
ffffffffc0202ac0:	00002617          	auipc	a2,0x2
ffffffffc0202ac4:	41860613          	addi	a2,a2,1048 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202ac8:	0e100593          	li	a1,225
ffffffffc0202acc:	00003517          	auipc	a0,0x3
ffffffffc0202ad0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202ad4:	e2efd0ef          	jal	ra,ffffffffc0200102 <__panic>
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202ad8:	00003617          	auipc	a2,0x3
ffffffffc0202adc:	c3060613          	addi	a2,a2,-976 # ffffffffc0205708 <commands+0x10b8>
ffffffffc0202ae0:	02800593          	li	a1,40
ffffffffc0202ae4:	00003517          	auipc	a0,0x3
ffffffffc0202ae8:	c4450513          	addi	a0,a0,-956 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202aec:	e16fd0ef          	jal	ra,ffffffffc0200102 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202af0:	00003697          	auipc	a3,0x3
ffffffffc0202af4:	e2068693          	addi	a3,a3,-480 # ffffffffc0205910 <commands+0x12c0>
ffffffffc0202af8:	00002617          	auipc	a2,0x2
ffffffffc0202afc:	3e060613          	addi	a2,a2,992 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202b00:	10000593          	li	a1,256
ffffffffc0202b04:	00003517          	auipc	a0,0x3
ffffffffc0202b08:	c2450513          	addi	a0,a0,-988 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202b0c:	df6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==4);
ffffffffc0202b10:	00003697          	auipc	a3,0x3
ffffffffc0202b14:	de068693          	addi	a3,a3,-544 # ffffffffc02058f0 <commands+0x12a0>
ffffffffc0202b18:	00002617          	auipc	a2,0x2
ffffffffc0202b1c:	3c060613          	addi	a2,a2,960 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202b20:	0a200593          	li	a1,162
ffffffffc0202b24:	00003517          	auipc	a0,0x3
ffffffffc0202b28:	c0450513          	addi	a0,a0,-1020 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202b2c:	dd6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==4);
ffffffffc0202b30:	00003697          	auipc	a3,0x3
ffffffffc0202b34:	dc068693          	addi	a3,a3,-576 # ffffffffc02058f0 <commands+0x12a0>
ffffffffc0202b38:	00002617          	auipc	a2,0x2
ffffffffc0202b3c:	3a060613          	addi	a2,a2,928 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202b40:	0a400593          	li	a1,164
ffffffffc0202b44:	00003517          	auipc	a0,0x3
ffffffffc0202b48:	be450513          	addi	a0,a0,-1052 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202b4c:	db6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert( nr_free == 0);         
ffffffffc0202b50:	00003697          	auipc	a3,0x3
ffffffffc0202b54:	db068693          	addi	a3,a3,-592 # ffffffffc0205900 <commands+0x12b0>
ffffffffc0202b58:	00002617          	auipc	a2,0x2
ffffffffc0202b5c:	38060613          	addi	a2,a2,896 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202b60:	0f800593          	li	a1,248
ffffffffc0202b64:	00003517          	auipc	a0,0x3
ffffffffc0202b68:	bc450513          	addi	a0,a0,-1084 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202b6c:	d96fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(ret==0);
ffffffffc0202b70:	00003697          	auipc	a3,0x3
ffffffffc0202b74:	e0868693          	addi	a3,a3,-504 # ffffffffc0205978 <commands+0x1328>
ffffffffc0202b78:	00002617          	auipc	a2,0x2
ffffffffc0202b7c:	36060613          	addi	a2,a2,864 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202b80:	10700593          	li	a1,263
ffffffffc0202b84:	00003517          	auipc	a0,0x3
ffffffffc0202b88:	ba450513          	addi	a0,a0,-1116 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202b8c:	d76fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202b90:	00003697          	auipc	a3,0x3
ffffffffc0202b94:	a4868693          	addi	a3,a3,-1464 # ffffffffc02055d8 <commands+0xf88>
ffffffffc0202b98:	00002617          	auipc	a2,0x2
ffffffffc0202b9c:	34060613          	addi	a2,a2,832 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202ba0:	0d100593          	li	a1,209
ffffffffc0202ba4:	00003517          	auipc	a0,0x3
ffffffffc0202ba8:	b8450513          	addi	a0,a0,-1148 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202bac:	d56fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(vma != NULL);
ffffffffc0202bb0:	00003697          	auipc	a3,0x3
ffffffffc0202bb4:	aa068693          	addi	a3,a3,-1376 # ffffffffc0205650 <commands+0x1000>
ffffffffc0202bb8:	00002617          	auipc	a2,0x2
ffffffffc0202bbc:	32060613          	addi	a2,a2,800 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202bc0:	0d400593          	li	a1,212
ffffffffc0202bc4:	00003517          	auipc	a0,0x3
ffffffffc0202bc8:	b6450513          	addi	a0,a0,-1180 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202bcc:	d36fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202bd0:	00003697          	auipc	a3,0x3
ffffffffc0202bd4:	c2868693          	addi	a3,a3,-984 # ffffffffc02057f8 <commands+0x11a8>
ffffffffc0202bd8:	00002617          	auipc	a2,0x2
ffffffffc0202bdc:	30060613          	addi	a2,a2,768 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202be0:	0dc00593          	li	a1,220
ffffffffc0202be4:	00003517          	auipc	a0,0x3
ffffffffc0202be8:	b4450513          	addi	a0,a0,-1212 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202bec:	d16fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202bf0:	00003697          	auipc	a3,0x3
ffffffffc0202bf4:	b7068693          	addi	a3,a3,-1168 # ffffffffc0205760 <commands+0x1110>
ffffffffc0202bf8:	00002617          	auipc	a2,0x2
ffffffffc0202bfc:	2e060613          	addi	a2,a2,736 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202c00:	0c400593          	li	a1,196
ffffffffc0202c04:	00003517          	auipc	a0,0x3
ffffffffc0202c08:	b2450513          	addi	a0,a0,-1244 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202c0c:	cf6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==2);
ffffffffc0202c10:	00003697          	auipc	a3,0x3
ffffffffc0202c14:	cc068693          	addi	a3,a3,-832 # ffffffffc02058d0 <commands+0x1280>
ffffffffc0202c18:	00002617          	auipc	a2,0x2
ffffffffc0202c1c:	2c060613          	addi	a2,a2,704 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202c20:	09a00593          	li	a1,154
ffffffffc0202c24:	00003517          	auipc	a0,0x3
ffffffffc0202c28:	b0450513          	addi	a0,a0,-1276 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202c2c:	cd6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==2);
ffffffffc0202c30:	00003697          	auipc	a3,0x3
ffffffffc0202c34:	ca068693          	addi	a3,a3,-864 # ffffffffc02058d0 <commands+0x1280>
ffffffffc0202c38:	00002617          	auipc	a2,0x2
ffffffffc0202c3c:	2a060613          	addi	a2,a2,672 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202c40:	09c00593          	li	a1,156
ffffffffc0202c44:	00003517          	auipc	a0,0x3
ffffffffc0202c48:	ae450513          	addi	a0,a0,-1308 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202c4c:	cb6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==3);
ffffffffc0202c50:	00003697          	auipc	a3,0x3
ffffffffc0202c54:	c9068693          	addi	a3,a3,-880 # ffffffffc02058e0 <commands+0x1290>
ffffffffc0202c58:	00002617          	auipc	a2,0x2
ffffffffc0202c5c:	28060613          	addi	a2,a2,640 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202c60:	09e00593          	li	a1,158
ffffffffc0202c64:	00003517          	auipc	a0,0x3
ffffffffc0202c68:	ac450513          	addi	a0,a0,-1340 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202c6c:	c96fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==3);
ffffffffc0202c70:	00003697          	auipc	a3,0x3
ffffffffc0202c74:	c7068693          	addi	a3,a3,-912 # ffffffffc02058e0 <commands+0x1290>
ffffffffc0202c78:	00002617          	auipc	a2,0x2
ffffffffc0202c7c:	26060613          	addi	a2,a2,608 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202c80:	0a000593          	li	a1,160
ffffffffc0202c84:	00003517          	auipc	a0,0x3
ffffffffc0202c88:	aa450513          	addi	a0,a0,-1372 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202c8c:	c76fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==1);
ffffffffc0202c90:	00003697          	auipc	a3,0x3
ffffffffc0202c94:	c3068693          	addi	a3,a3,-976 # ffffffffc02058c0 <commands+0x1270>
ffffffffc0202c98:	00002617          	auipc	a2,0x2
ffffffffc0202c9c:	24060613          	addi	a2,a2,576 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202ca0:	09600593          	li	a1,150
ffffffffc0202ca4:	00003517          	auipc	a0,0x3
ffffffffc0202ca8:	a8450513          	addi	a0,a0,-1404 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202cac:	c56fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(pgfault_num==1);
ffffffffc0202cb0:	00003697          	auipc	a3,0x3
ffffffffc0202cb4:	c1068693          	addi	a3,a3,-1008 # ffffffffc02058c0 <commands+0x1270>
ffffffffc0202cb8:	00002617          	auipc	a2,0x2
ffffffffc0202cbc:	22060613          	addi	a2,a2,544 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202cc0:	09800593          	li	a1,152
ffffffffc0202cc4:	00003517          	auipc	a0,0x3
ffffffffc0202cc8:	a6450513          	addi	a0,a0,-1436 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202ccc:	c36fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(mm != NULL);
ffffffffc0202cd0:	00003697          	auipc	a3,0x3
ffffffffc0202cd4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0205678 <commands+0x1028>
ffffffffc0202cd8:	00002617          	auipc	a2,0x2
ffffffffc0202cdc:	20060613          	addi	a2,a2,512 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202ce0:	0c900593          	li	a1,201
ffffffffc0202ce4:	00003517          	auipc	a0,0x3
ffffffffc0202ce8:	a4450513          	addi	a0,a0,-1468 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202cec:	c16fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202cf0:	00003697          	auipc	a3,0x3
ffffffffc0202cf4:	ab868693          	addi	a3,a3,-1352 # ffffffffc02057a8 <commands+0x1158>
ffffffffc0202cf8:	00002617          	auipc	a2,0x2
ffffffffc0202cfc:	1e060613          	addi	a2,a2,480 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202d00:	0cc00593          	li	a1,204
ffffffffc0202d04:	00003517          	auipc	a0,0x3
ffffffffc0202d08:	a2450513          	addi	a0,a0,-1500 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202d0c:	bf6fd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202d10:	00003697          	auipc	a3,0x3
ffffffffc0202d14:	b6068693          	addi	a3,a3,-1184 # ffffffffc0205870 <commands+0x1220>
ffffffffc0202d18:	00002617          	auipc	a2,0x2
ffffffffc0202d1c:	1c060613          	addi	a2,a2,448 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202d20:	0ef00593          	li	a1,239
ffffffffc0202d24:	00003517          	auipc	a0,0x3
ffffffffc0202d28:	a0450513          	addi	a0,a0,-1532 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202d2c:	bd6fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202d30 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202d30:	0000f797          	auipc	a5,0xf
ffffffffc0202d34:	8287b783          	ld	a5,-2008(a5) # ffffffffc0211558 <sm>
ffffffffc0202d38:	6b9c                	ld	a5,16(a5)
ffffffffc0202d3a:	8782                	jr	a5

ffffffffc0202d3c <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202d3c:	0000f797          	auipc	a5,0xf
ffffffffc0202d40:	81c7b783          	ld	a5,-2020(a5) # ffffffffc0211558 <sm>
ffffffffc0202d44:	739c                	ld	a5,32(a5)
ffffffffc0202d46:	8782                	jr	a5

ffffffffc0202d48 <swap_out>:
{
ffffffffc0202d48:	711d                	addi	sp,sp,-96
ffffffffc0202d4a:	ec86                	sd	ra,88(sp)
ffffffffc0202d4c:	e8a2                	sd	s0,80(sp)
ffffffffc0202d4e:	e4a6                	sd	s1,72(sp)
ffffffffc0202d50:	e0ca                	sd	s2,64(sp)
ffffffffc0202d52:	fc4e                	sd	s3,56(sp)
ffffffffc0202d54:	f852                	sd	s4,48(sp)
ffffffffc0202d56:	f456                	sd	s5,40(sp)
ffffffffc0202d58:	f05a                	sd	s6,32(sp)
ffffffffc0202d5a:	ec5e                	sd	s7,24(sp)
ffffffffc0202d5c:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0202d5e:	cde9                	beqz	a1,ffffffffc0202e38 <swap_out+0xf0>
ffffffffc0202d60:	8a2e                	mv	s4,a1
ffffffffc0202d62:	892a                	mv	s2,a0
ffffffffc0202d64:	8ab2                	mv	s5,a2
ffffffffc0202d66:	4401                	li	s0,0
ffffffffc0202d68:	0000e997          	auipc	s3,0xe
ffffffffc0202d6c:	7f098993          	addi	s3,s3,2032 # ffffffffc0211558 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202d70:	00003b17          	auipc	s6,0x3
ffffffffc0202d74:	cb0b0b13          	addi	s6,s6,-848 # ffffffffc0205a20 <commands+0x13d0>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202d78:	00003b97          	auipc	s7,0x3
ffffffffc0202d7c:	c90b8b93          	addi	s7,s7,-880 # ffffffffc0205a08 <commands+0x13b8>
ffffffffc0202d80:	a825                	j	ffffffffc0202db8 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202d82:	67a2                	ld	a5,8(sp)
ffffffffc0202d84:	8626                	mv	a2,s1
ffffffffc0202d86:	85a2                	mv	a1,s0
ffffffffc0202d88:	63b4                	ld	a3,64(a5)
ffffffffc0202d8a:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0202d8c:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202d8e:	82b1                	srli	a3,a3,0xc
ffffffffc0202d90:	0685                	addi	a3,a3,1
ffffffffc0202d92:	b28fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;//将页表项 ptep 更新为交换空间中的页号
ffffffffc0202d96:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0202d98:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;//将页表项 ptep 更新为交换空间中的页号
ffffffffc0202d9a:	613c                	ld	a5,64(a0)
ffffffffc0202d9c:	83b1                	srli	a5,a5,0xc
ffffffffc0202d9e:	0785                	addi	a5,a5,1
ffffffffc0202da0:	07a2                	slli	a5,a5,0x8
ffffffffc0202da2:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0202da6:	dd5fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
          tlb_invalidate(mm->pgdir, v);//刷新TLB
ffffffffc0202daa:	01893503          	ld	a0,24(s2)
ffffffffc0202dae:	85a6                	mv	a1,s1
ffffffffc0202db0:	e33fe0ef          	jal	ra,ffffffffc0201be2 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0202db4:	048a0d63          	beq	s4,s0,ffffffffc0202e0e <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);//调用页面置换算法的接口 r=0表示成功找到了可以换出去的页面 要换出去的物理页面存在page里
ffffffffc0202db8:	0009b783          	ld	a5,0(s3)
ffffffffc0202dbc:	8656                	mv	a2,s5
ffffffffc0202dbe:	002c                	addi	a1,sp,8
ffffffffc0202dc0:	7b9c                	ld	a5,48(a5)
ffffffffc0202dc2:	854a                	mv	a0,s2
ffffffffc0202dc4:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0202dc6:	e12d                	bnez	a0,ffffffffc0202e28 <swap_out+0xe0>
          v=page->pra_vaddr; //获取要换出页面的虚拟地址，并保存在 v 中
ffffffffc0202dc8:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);//获取与虚拟地址 v 相关联的页表项（Page Table Entry）的指针
ffffffffc0202dca:	01893503          	ld	a0,24(s2)
ffffffffc0202dce:	4601                	li	a2,0
          v=page->pra_vaddr; //获取要换出页面的虚拟地址，并保存在 v 中
ffffffffc0202dd0:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);//获取与虚拟地址 v 相关联的页表项（Page Table Entry）的指针
ffffffffc0202dd2:	85a6                	mv	a1,s1
ffffffffc0202dd4:	e21fd0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202dd8:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);//获取与虚拟地址 v 相关联的页表项（Page Table Entry）的指针
ffffffffc0202dda:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0202ddc:	8b85                	andi	a5,a5,1
ffffffffc0202dde:	cfb9                	beqz	a5,ffffffffc0202e3c <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {//将页面写入交换空间
ffffffffc0202de0:	65a2                	ld	a1,8(sp)
ffffffffc0202de2:	61bc                	ld	a5,64(a1)
ffffffffc0202de4:	83b1                	srli	a5,a5,0xc
ffffffffc0202de6:	0785                	addi	a5,a5,1
ffffffffc0202de8:	00879513          	slli	a0,a5,0x8
ffffffffc0202dec:	006010ef          	jal	ra,ffffffffc0203df2 <swapfs_write>
ffffffffc0202df0:	d949                	beqz	a0,ffffffffc0202d82 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202df2:	855e                	mv	a0,s7
ffffffffc0202df4:	ac6fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202df8:	0009b783          	ld	a5,0(s3)
ffffffffc0202dfc:	6622                	ld	a2,8(sp)
ffffffffc0202dfe:	4681                	li	a3,0
ffffffffc0202e00:	739c                	ld	a5,32(a5)
ffffffffc0202e02:	85a6                	mv	a1,s1
ffffffffc0202e04:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0202e06:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202e08:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0202e0a:	fa8a17e3          	bne	s4,s0,ffffffffc0202db8 <swap_out+0x70>
}
ffffffffc0202e0e:	60e6                	ld	ra,88(sp)
ffffffffc0202e10:	8522                	mv	a0,s0
ffffffffc0202e12:	6446                	ld	s0,80(sp)
ffffffffc0202e14:	64a6                	ld	s1,72(sp)
ffffffffc0202e16:	6906                	ld	s2,64(sp)
ffffffffc0202e18:	79e2                	ld	s3,56(sp)
ffffffffc0202e1a:	7a42                	ld	s4,48(sp)
ffffffffc0202e1c:	7aa2                	ld	s5,40(sp)
ffffffffc0202e1e:	7b02                	ld	s6,32(sp)
ffffffffc0202e20:	6be2                	ld	s7,24(sp)
ffffffffc0202e22:	6c42                	ld	s8,16(sp)
ffffffffc0202e24:	6125                	addi	sp,sp,96
ffffffffc0202e26:	8082                	ret
               cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0202e28:	85a2                	mv	a1,s0
ffffffffc0202e2a:	00003517          	auipc	a0,0x3
ffffffffc0202e2e:	b9650513          	addi	a0,a0,-1130 # ffffffffc02059c0 <commands+0x1370>
ffffffffc0202e32:	a88fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
               break;
ffffffffc0202e36:	bfe1                	j	ffffffffc0202e0e <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0202e38:	4401                	li	s0,0
ffffffffc0202e3a:	bfd1                	j	ffffffffc0202e0e <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202e3c:	00003697          	auipc	a3,0x3
ffffffffc0202e40:	bb468693          	addi	a3,a3,-1100 # ffffffffc02059f0 <commands+0x13a0>
ffffffffc0202e44:	00002617          	auipc	a2,0x2
ffffffffc0202e48:	09460613          	addi	a2,a2,148 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202e4c:	06900593          	li	a1,105
ffffffffc0202e50:	00003517          	auipc	a0,0x3
ffffffffc0202e54:	8d850513          	addi	a0,a0,-1832 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202e58:	aaafd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202e5c <swap_in>:
{
ffffffffc0202e5c:	7179                	addi	sp,sp,-48
ffffffffc0202e5e:	e84a                	sd	s2,16(sp)
ffffffffc0202e60:	892a                	mv	s2,a0
     struct Page *result = alloc_page();//这里alloc_page()内部可能调用swap_out()
ffffffffc0202e62:	4505                	li	a0,1
{
ffffffffc0202e64:	ec26                	sd	s1,24(sp)
ffffffffc0202e66:	e44e                	sd	s3,8(sp)
ffffffffc0202e68:	f406                	sd	ra,40(sp)
ffffffffc0202e6a:	f022                	sd	s0,32(sp)
ffffffffc0202e6c:	84ae                	mv	s1,a1
ffffffffc0202e6e:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();//这里alloc_page()内部可能调用swap_out()
ffffffffc0202e70:	c79fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
     assert(result!=NULL);
ffffffffc0202e74:	c129                	beqz	a0,ffffffffc0202eb6 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);//找到/构建对应的页表项
ffffffffc0202e76:	842a                	mv	s0,a0
ffffffffc0202e78:	01893503          	ld	a0,24(s2)
ffffffffc0202e7c:	4601                	li	a2,0
ffffffffc0202e7e:	85a6                	mv	a1,s1
ffffffffc0202e80:	d75fd0ef          	jal	ra,ffffffffc0200bf4 <get_pte>
ffffffffc0202e84:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)//将数据从硬盘读到内存
ffffffffc0202e86:	6108                	ld	a0,0(a0)
ffffffffc0202e88:	85a2                	mv	a1,s0
ffffffffc0202e8a:	6cf000ef          	jal	ra,ffffffffc0203d58 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0202e8e:	00093583          	ld	a1,0(s2)
ffffffffc0202e92:	8626                	mv	a2,s1
ffffffffc0202e94:	00003517          	auipc	a0,0x3
ffffffffc0202e98:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0205a70 <commands+0x1420>
ffffffffc0202e9c:	81a1                	srli	a1,a1,0x8
ffffffffc0202e9e:	a1cfd0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0202ea2:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0202ea4:	0089b023          	sd	s0,0(s3)
}
ffffffffc0202ea8:	7402                	ld	s0,32(sp)
ffffffffc0202eaa:	64e2                	ld	s1,24(sp)
ffffffffc0202eac:	6942                	ld	s2,16(sp)
ffffffffc0202eae:	69a2                	ld	s3,8(sp)
ffffffffc0202eb0:	4501                	li	a0,0
ffffffffc0202eb2:	6145                	addi	sp,sp,48
ffffffffc0202eb4:	8082                	ret
     assert(result!=NULL);
ffffffffc0202eb6:	00003697          	auipc	a3,0x3
ffffffffc0202eba:	baa68693          	addi	a3,a3,-1110 # ffffffffc0205a60 <commands+0x1410>
ffffffffc0202ebe:	00002617          	auipc	a2,0x2
ffffffffc0202ec2:	01a60613          	addi	a2,a2,26 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202ec6:	08000593          	li	a1,128
ffffffffc0202eca:	00003517          	auipc	a0,0x3
ffffffffc0202ece:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205728 <commands+0x10d8>
ffffffffc0202ed2:	a30fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202ed6 <_clock_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0202ed6:	0000e797          	auipc	a5,0xe
ffffffffc0202eda:	1fa78793          	addi	a5,a5,506 # ffffffffc02110d0 <pra_list_head>
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作

    list_init(&pra_list_head);
    curr_ptr = &pra_list_head;
    mm->sm_priv = &pra_list_head;
ffffffffc0202ede:	f51c                	sd	a5,40(a0)
ffffffffc0202ee0:	e79c                	sd	a5,8(a5)
ffffffffc0202ee2:	e39c                	sd	a5,0(a5)
    curr_ptr = &pra_list_head;
ffffffffc0202ee4:	0000e717          	auipc	a4,0xe
ffffffffc0202ee8:	68f73223          	sd	a5,1668(a4) # ffffffffc0211568 <curr_ptr>

     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
ffffffffc0202eec:	4501                	li	a0,0
ffffffffc0202eee:	8082                	ret

ffffffffc0202ef0 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc0202ef0:	4501                	li	a0,0
ffffffffc0202ef2:	8082                	ret

ffffffffc0202ef4 <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0202ef4:	4501                	li	a0,0
ffffffffc0202ef6:	8082                	ret

ffffffffc0202ef8 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0202ef8:	4501                	li	a0,0
ffffffffc0202efa:	8082                	ret

ffffffffc0202efc <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc0202efc:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202efe:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc0202f00:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202f02:	678d                	lui	a5,0x3
ffffffffc0202f04:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0202f08:	0000e697          	auipc	a3,0xe
ffffffffc0202f0c:	6406a683          	lw	a3,1600(a3) # ffffffffc0211548 <pgfault_num>
ffffffffc0202f10:	4711                	li	a4,4
ffffffffc0202f12:	0ae69363          	bne	a3,a4,ffffffffc0202fb8 <_clock_check_swap+0xbc>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202f16:	6705                	lui	a4,0x1
ffffffffc0202f18:	4629                	li	a2,10
ffffffffc0202f1a:	0000e797          	auipc	a5,0xe
ffffffffc0202f1e:	62e78793          	addi	a5,a5,1582 # ffffffffc0211548 <pgfault_num>
ffffffffc0202f22:	00c70023          	sb	a2,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc0202f26:	4398                	lw	a4,0(a5)
ffffffffc0202f28:	2701                	sext.w	a4,a4
ffffffffc0202f2a:	20d71763          	bne	a4,a3,ffffffffc0203138 <_clock_check_swap+0x23c>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202f2e:	6691                	lui	a3,0x4
ffffffffc0202f30:	4635                	li	a2,13
ffffffffc0202f32:	00c68023          	sb	a2,0(a3) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc0202f36:	4394                	lw	a3,0(a5)
ffffffffc0202f38:	2681                	sext.w	a3,a3
ffffffffc0202f3a:	1ce69f63          	bne	a3,a4,ffffffffc0203118 <_clock_check_swap+0x21c>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202f3e:	6709                	lui	a4,0x2
ffffffffc0202f40:	462d                	li	a2,11
ffffffffc0202f42:	00c70023          	sb	a2,0(a4) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0202f46:	4398                	lw	a4,0(a5)
ffffffffc0202f48:	2701                	sext.w	a4,a4
ffffffffc0202f4a:	1ad71763          	bne	a4,a3,ffffffffc02030f8 <_clock_check_swap+0x1fc>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0202f4e:	6715                	lui	a4,0x5
ffffffffc0202f50:	46b9                	li	a3,14
ffffffffc0202f52:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0202f56:	4398                	lw	a4,0(a5)
ffffffffc0202f58:	4695                	li	a3,5
ffffffffc0202f5a:	2701                	sext.w	a4,a4
ffffffffc0202f5c:	16d71e63          	bne	a4,a3,ffffffffc02030d8 <_clock_check_swap+0x1dc>
    assert(pgfault_num==5);
ffffffffc0202f60:	4394                	lw	a3,0(a5)
ffffffffc0202f62:	2681                	sext.w	a3,a3
ffffffffc0202f64:	14e69a63          	bne	a3,a4,ffffffffc02030b8 <_clock_check_swap+0x1bc>
    assert(pgfault_num==5);
ffffffffc0202f68:	4398                	lw	a4,0(a5)
ffffffffc0202f6a:	2701                	sext.w	a4,a4
ffffffffc0202f6c:	12d71663          	bne	a4,a3,ffffffffc0203098 <_clock_check_swap+0x19c>
    assert(pgfault_num==5);
ffffffffc0202f70:	4394                	lw	a3,0(a5)
ffffffffc0202f72:	2681                	sext.w	a3,a3
ffffffffc0202f74:	10e69263          	bne	a3,a4,ffffffffc0203078 <_clock_check_swap+0x17c>
    assert(pgfault_num==5);
ffffffffc0202f78:	4398                	lw	a4,0(a5)
ffffffffc0202f7a:	2701                	sext.w	a4,a4
ffffffffc0202f7c:	0cd71e63          	bne	a4,a3,ffffffffc0203058 <_clock_check_swap+0x15c>
    assert(pgfault_num==5);
ffffffffc0202f80:	4394                	lw	a3,0(a5)
ffffffffc0202f82:	2681                	sext.w	a3,a3
ffffffffc0202f84:	0ae69a63          	bne	a3,a4,ffffffffc0203038 <_clock_check_swap+0x13c>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0202f88:	6715                	lui	a4,0x5
ffffffffc0202f8a:	46b9                	li	a3,14
ffffffffc0202f8c:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0202f90:	4398                	lw	a4,0(a5)
ffffffffc0202f92:	4695                	li	a3,5
ffffffffc0202f94:	2701                	sext.w	a4,a4
ffffffffc0202f96:	08d71163          	bne	a4,a3,ffffffffc0203018 <_clock_check_swap+0x11c>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202f9a:	6705                	lui	a4,0x1
ffffffffc0202f9c:	00074683          	lbu	a3,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202fa0:	4729                	li	a4,10
ffffffffc0202fa2:	04e69b63          	bne	a3,a4,ffffffffc0202ff8 <_clock_check_swap+0xfc>
    assert(pgfault_num==6);
ffffffffc0202fa6:	439c                	lw	a5,0(a5)
ffffffffc0202fa8:	4719                	li	a4,6
ffffffffc0202faa:	2781                	sext.w	a5,a5
ffffffffc0202fac:	02e79663          	bne	a5,a4,ffffffffc0202fd8 <_clock_check_swap+0xdc>
}
ffffffffc0202fb0:	60a2                	ld	ra,8(sp)
ffffffffc0202fb2:	4501                	li	a0,0
ffffffffc0202fb4:	0141                	addi	sp,sp,16
ffffffffc0202fb6:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0202fb8:	00003697          	auipc	a3,0x3
ffffffffc0202fbc:	93868693          	addi	a3,a3,-1736 # ffffffffc02058f0 <commands+0x12a0>
ffffffffc0202fc0:	00002617          	auipc	a2,0x2
ffffffffc0202fc4:	f1860613          	addi	a2,a2,-232 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202fc8:	09100593          	li	a1,145
ffffffffc0202fcc:	00003517          	auipc	a0,0x3
ffffffffc0202fd0:	ae450513          	addi	a0,a0,-1308 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0202fd4:	92efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==6);
ffffffffc0202fd8:	00003697          	auipc	a3,0x3
ffffffffc0202fdc:	b2868693          	addi	a3,a3,-1240 # ffffffffc0205b00 <commands+0x14b0>
ffffffffc0202fe0:	00002617          	auipc	a2,0x2
ffffffffc0202fe4:	ef860613          	addi	a2,a2,-264 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0202fe8:	0a800593          	li	a1,168
ffffffffc0202fec:	00003517          	auipc	a0,0x3
ffffffffc0202ff0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0202ff4:	90efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202ff8:	00003697          	auipc	a3,0x3
ffffffffc0202ffc:	ae068693          	addi	a3,a3,-1312 # ffffffffc0205ad8 <commands+0x1488>
ffffffffc0203000:	00002617          	auipc	a2,0x2
ffffffffc0203004:	ed860613          	addi	a2,a2,-296 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203008:	0a600593          	li	a1,166
ffffffffc020300c:	00003517          	auipc	a0,0x3
ffffffffc0203010:	aa450513          	addi	a0,a0,-1372 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203014:	8eefd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0203018:	00003697          	auipc	a3,0x3
ffffffffc020301c:	ab068693          	addi	a3,a3,-1360 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc0203020:	00002617          	auipc	a2,0x2
ffffffffc0203024:	eb860613          	addi	a2,a2,-328 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203028:	0a500593          	li	a1,165
ffffffffc020302c:	00003517          	auipc	a0,0x3
ffffffffc0203030:	a8450513          	addi	a0,a0,-1404 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203034:	8cefd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0203038:	00003697          	auipc	a3,0x3
ffffffffc020303c:	a9068693          	addi	a3,a3,-1392 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc0203040:	00002617          	auipc	a2,0x2
ffffffffc0203044:	e9860613          	addi	a2,a2,-360 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203048:	0a300593          	li	a1,163
ffffffffc020304c:	00003517          	auipc	a0,0x3
ffffffffc0203050:	a6450513          	addi	a0,a0,-1436 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203054:	8aefd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0203058:	00003697          	auipc	a3,0x3
ffffffffc020305c:	a7068693          	addi	a3,a3,-1424 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc0203060:	00002617          	auipc	a2,0x2
ffffffffc0203064:	e7860613          	addi	a2,a2,-392 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203068:	0a100593          	li	a1,161
ffffffffc020306c:	00003517          	auipc	a0,0x3
ffffffffc0203070:	a4450513          	addi	a0,a0,-1468 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203074:	88efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0203078:	00003697          	auipc	a3,0x3
ffffffffc020307c:	a5068693          	addi	a3,a3,-1456 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc0203080:	00002617          	auipc	a2,0x2
ffffffffc0203084:	e5860613          	addi	a2,a2,-424 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203088:	09f00593          	li	a1,159
ffffffffc020308c:	00003517          	auipc	a0,0x3
ffffffffc0203090:	a2450513          	addi	a0,a0,-1500 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203094:	86efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0203098:	00003697          	auipc	a3,0x3
ffffffffc020309c:	a3068693          	addi	a3,a3,-1488 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc02030a0:	00002617          	auipc	a2,0x2
ffffffffc02030a4:	e3860613          	addi	a2,a2,-456 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02030a8:	09d00593          	li	a1,157
ffffffffc02030ac:	00003517          	auipc	a0,0x3
ffffffffc02030b0:	a0450513          	addi	a0,a0,-1532 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc02030b4:	84efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc02030b8:	00003697          	auipc	a3,0x3
ffffffffc02030bc:	a1068693          	addi	a3,a3,-1520 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc02030c0:	00002617          	auipc	a2,0x2
ffffffffc02030c4:	e1860613          	addi	a2,a2,-488 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02030c8:	09b00593          	li	a1,155
ffffffffc02030cc:	00003517          	auipc	a0,0x3
ffffffffc02030d0:	9e450513          	addi	a0,a0,-1564 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc02030d4:	82efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc02030d8:	00003697          	auipc	a3,0x3
ffffffffc02030dc:	9f068693          	addi	a3,a3,-1552 # ffffffffc0205ac8 <commands+0x1478>
ffffffffc02030e0:	00002617          	auipc	a2,0x2
ffffffffc02030e4:	df860613          	addi	a2,a2,-520 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02030e8:	09900593          	li	a1,153
ffffffffc02030ec:	00003517          	auipc	a0,0x3
ffffffffc02030f0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc02030f4:	80efd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc02030f8:	00002697          	auipc	a3,0x2
ffffffffc02030fc:	7f868693          	addi	a3,a3,2040 # ffffffffc02058f0 <commands+0x12a0>
ffffffffc0203100:	00002617          	auipc	a2,0x2
ffffffffc0203104:	dd860613          	addi	a2,a2,-552 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203108:	09700593          	li	a1,151
ffffffffc020310c:	00003517          	auipc	a0,0x3
ffffffffc0203110:	9a450513          	addi	a0,a0,-1628 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203114:	feffc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0203118:	00002697          	auipc	a3,0x2
ffffffffc020311c:	7d868693          	addi	a3,a3,2008 # ffffffffc02058f0 <commands+0x12a0>
ffffffffc0203120:	00002617          	auipc	a2,0x2
ffffffffc0203124:	db860613          	addi	a2,a2,-584 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203128:	09500593          	li	a1,149
ffffffffc020312c:	00003517          	auipc	a0,0x3
ffffffffc0203130:	98450513          	addi	a0,a0,-1660 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203134:	fcffc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0203138:	00002697          	auipc	a3,0x2
ffffffffc020313c:	7b868693          	addi	a3,a3,1976 # ffffffffc02058f0 <commands+0x12a0>
ffffffffc0203140:	00002617          	auipc	a2,0x2
ffffffffc0203144:	d9860613          	addi	a2,a2,-616 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203148:	09300593          	li	a1,147
ffffffffc020314c:	00003517          	auipc	a0,0x3
ffffffffc0203150:	96450513          	addi	a0,a0,-1692 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc0203154:	faffc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203158 <_clock_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203158:	7514                	ld	a3,40(a0)
{
ffffffffc020315a:	1141                	addi	sp,sp,-16
ffffffffc020315c:	e406                	sd	ra,8(sp)
        assert(head != NULL);
ffffffffc020315e:	c2d1                	beqz	a3,ffffffffc02031e2 <_clock_swap_out_victim+0x8a>
    assert(in_tick==0);
ffffffffc0203160:	e22d                	bnez	a2,ffffffffc02031c2 <_clock_swap_out_victim+0x6a>
    return listelm->next;
ffffffffc0203162:	0000e617          	auipc	a2,0xe
ffffffffc0203166:	40660613          	addi	a2,a2,1030 # ffffffffc0211568 <curr_ptr>
ffffffffc020316a:	621c                	ld	a5,0(a2)
ffffffffc020316c:	852e                	mv	a0,a1
ffffffffc020316e:	678c                	ld	a1,8(a5)
ffffffffc0203170:	a039                	j	ffffffffc020317e <_clock_swap_out_victim+0x26>
        if(!page->visited) {
ffffffffc0203172:	fe05b703          	ld	a4,-32(a1) # fe0 <kern_entry-0xffffffffc01ff020>
ffffffffc0203176:	cf11                	beqz	a4,ffffffffc0203192 <_clock_swap_out_victim+0x3a>
            page->visited = 0;
ffffffffc0203178:	fe05b023          	sd	zero,-32(a1)
    while (1) {
ffffffffc020317c:	85be                	mv	a1,a5
ffffffffc020317e:	659c                	ld	a5,8(a1)
        if(curr_ptr == head) {
ffffffffc0203180:	feb699e3          	bne	a3,a1,ffffffffc0203172 <_clock_swap_out_victim+0x1a>
            if(curr_ptr == head) {
ffffffffc0203184:	02d78863          	beq	a5,a3,ffffffffc02031b4 <_clock_swap_out_victim+0x5c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203188:	85be                	mv	a1,a5
        if(!page->visited) {
ffffffffc020318a:	fe05b703          	ld	a4,-32(a1)
ffffffffc020318e:	679c                	ld	a5,8(a5)
ffffffffc0203190:	f765                	bnez	a4,ffffffffc0203178 <_clock_swap_out_victim+0x20>
ffffffffc0203192:	6198                	ld	a4,0(a1)
        struct Page* page = le2page(curr_ptr, pra_page_link);
ffffffffc0203194:	fd058693          	addi	a3,a1,-48
            *ptr_page = page;
ffffffffc0203198:	e114                	sd	a3,0(a0)
    prev->next = next;
ffffffffc020319a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020319c:	e398                	sd	a4,0(a5)
            cprintf("curr_ptr %p\n",curr_ptr);
ffffffffc020319e:	00003517          	auipc	a0,0x3
ffffffffc02031a2:	99250513          	addi	a0,a0,-1646 # ffffffffc0205b30 <commands+0x14e0>
ffffffffc02031a6:	e20c                	sd	a1,0(a2)
ffffffffc02031a8:	f13fc0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc02031ac:	60a2                	ld	ra,8(sp)
ffffffffc02031ae:	4501                	li	a0,0
ffffffffc02031b0:	0141                	addi	sp,sp,16
ffffffffc02031b2:	8082                	ret
ffffffffc02031b4:	60a2                	ld	ra,8(sp)
                *ptr_page = NULL;
ffffffffc02031b6:	00053023          	sd	zero,0(a0)
ffffffffc02031ba:	e214                	sd	a3,0(a2)
}
ffffffffc02031bc:	4501                	li	a0,0
ffffffffc02031be:	0141                	addi	sp,sp,16
ffffffffc02031c0:	8082                	ret
    assert(in_tick==0);
ffffffffc02031c2:	00003697          	auipc	a3,0x3
ffffffffc02031c6:	95e68693          	addi	a3,a3,-1698 # ffffffffc0205b20 <commands+0x14d0>
ffffffffc02031ca:	00002617          	auipc	a2,0x2
ffffffffc02031ce:	d0e60613          	addi	a2,a2,-754 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02031d2:	04c00593          	li	a1,76
ffffffffc02031d6:	00003517          	auipc	a0,0x3
ffffffffc02031da:	8da50513          	addi	a0,a0,-1830 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc02031de:	f25fc0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(head != NULL);
ffffffffc02031e2:	00003697          	auipc	a3,0x3
ffffffffc02031e6:	92e68693          	addi	a3,a3,-1746 # ffffffffc0205b10 <commands+0x14c0>
ffffffffc02031ea:	00002617          	auipc	a2,0x2
ffffffffc02031ee:	cee60613          	addi	a2,a2,-786 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02031f2:	04b00593          	li	a1,75
ffffffffc02031f6:	00003517          	auipc	a0,0x3
ffffffffc02031fa:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0205ab0 <commands+0x1460>
ffffffffc02031fe:	f05fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203202 <_clock_map_swappable>:
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203202:	0000e797          	auipc	a5,0xe
ffffffffc0203206:	3667b783          	ld	a5,870(a5) # ffffffffc0211568 <curr_ptr>
ffffffffc020320a:	cf89                	beqz	a5,ffffffffc0203224 <_clock_map_swappable+0x22>
    list_add_before((list_entry_t*) mm->sm_priv,entry);
ffffffffc020320c:	751c                	ld	a5,40(a0)
ffffffffc020320e:	03060713          	addi	a4,a2,48
}
ffffffffc0203212:	4501                	li	a0,0
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203214:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203216:	e398                	sd	a4,0(a5)
ffffffffc0203218:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc020321a:	fe1c                	sd	a5,56(a2)
    page->visited = 1;
ffffffffc020321c:	4785                	li	a5,1
    elm->prev = prev;
ffffffffc020321e:	fa14                	sd	a3,48(a2)
ffffffffc0203220:	ea1c                	sd	a5,16(a2)
}
ffffffffc0203222:	8082                	ret
{
ffffffffc0203224:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203226:	00003697          	auipc	a3,0x3
ffffffffc020322a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0205b40 <commands+0x14f0>
ffffffffc020322e:	00002617          	auipc	a2,0x2
ffffffffc0203232:	caa60613          	addi	a2,a2,-854 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203236:	03800593          	li	a1,56
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	87650513          	addi	a0,a0,-1930 # ffffffffc0205ab0 <commands+0x1460>
{
ffffffffc0203242:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203244:	ebffc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203248 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0203248:	0000e797          	auipc	a5,0xe
ffffffffc020324c:	e9878793          	addi	a5,a5,-360 # ffffffffc02110e0 <free_area>
ffffffffc0203250:	e79c                	sd	a5,8(a5)
ffffffffc0203252:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0203254:	0007a823          	sw	zero,16(a5)
}
ffffffffc0203258:	8082                	ret

ffffffffc020325a <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020325a:	0000e517          	auipc	a0,0xe
ffffffffc020325e:	e9656503          	lwu	a0,-362(a0) # ffffffffc02110f0 <free_area+0x10>
ffffffffc0203262:	8082                	ret

ffffffffc0203264 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0203264:	715d                	addi	sp,sp,-80
ffffffffc0203266:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0203268:	0000e417          	auipc	s0,0xe
ffffffffc020326c:	e7840413          	addi	s0,s0,-392 # ffffffffc02110e0 <free_area>
ffffffffc0203270:	641c                	ld	a5,8(s0)
ffffffffc0203272:	e486                	sd	ra,72(sp)
ffffffffc0203274:	fc26                	sd	s1,56(sp)
ffffffffc0203276:	f84a                	sd	s2,48(sp)
ffffffffc0203278:	f44e                	sd	s3,40(sp)
ffffffffc020327a:	f052                	sd	s4,32(sp)
ffffffffc020327c:	ec56                	sd	s5,24(sp)
ffffffffc020327e:	e85a                	sd	s6,16(sp)
ffffffffc0203280:	e45e                	sd	s7,8(sp)
ffffffffc0203282:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203284:	2c878763          	beq	a5,s0,ffffffffc0203552 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0203288:	4481                	li	s1,0
ffffffffc020328a:	4901                	li	s2,0
ffffffffc020328c:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203290:	8b09                	andi	a4,a4,2
ffffffffc0203292:	2c070463          	beqz	a4,ffffffffc020355a <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0203296:	ff87a703          	lw	a4,-8(a5)
ffffffffc020329a:	679c                	ld	a5,8(a5)
ffffffffc020329c:	2905                	addiw	s2,s2,1
ffffffffc020329e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02032a0:	fe8796e3          	bne	a5,s0,ffffffffc020328c <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02032a4:	89a6                	mv	s3,s1
ffffffffc02032a6:	915fd0ef          	jal	ra,ffffffffc0200bba <nr_free_pages>
ffffffffc02032aa:	71351863          	bne	a0,s3,ffffffffc02039ba <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02032ae:	4505                	li	a0,1
ffffffffc02032b0:	839fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02032b4:	8a2a                	mv	s4,a0
ffffffffc02032b6:	44050263          	beqz	a0,ffffffffc02036fa <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02032ba:	4505                	li	a0,1
ffffffffc02032bc:	82dfd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02032c0:	89aa                	mv	s3,a0
ffffffffc02032c2:	70050c63          	beqz	a0,ffffffffc02039da <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02032c6:	4505                	li	a0,1
ffffffffc02032c8:	821fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02032cc:	8aaa                	mv	s5,a0
ffffffffc02032ce:	4a050663          	beqz	a0,ffffffffc020377a <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02032d2:	2b3a0463          	beq	s4,s3,ffffffffc020357a <default_check+0x316>
ffffffffc02032d6:	2aaa0263          	beq	s4,a0,ffffffffc020357a <default_check+0x316>
ffffffffc02032da:	2aa98063          	beq	s3,a0,ffffffffc020357a <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02032de:	000a2783          	lw	a5,0(s4)
ffffffffc02032e2:	2a079c63          	bnez	a5,ffffffffc020359a <default_check+0x336>
ffffffffc02032e6:	0009a783          	lw	a5,0(s3)
ffffffffc02032ea:	2a079863          	bnez	a5,ffffffffc020359a <default_check+0x336>
ffffffffc02032ee:	411c                	lw	a5,0(a0)
ffffffffc02032f0:	2a079563          	bnez	a5,ffffffffc020359a <default_check+0x336>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02032f4:	0000e797          	auipc	a5,0xe
ffffffffc02032f8:	2347b783          	ld	a5,564(a5) # ffffffffc0211528 <pages>
ffffffffc02032fc:	40fa0733          	sub	a4,s4,a5
ffffffffc0203300:	870d                	srai	a4,a4,0x3
ffffffffc0203302:	00003597          	auipc	a1,0x3
ffffffffc0203306:	ebe5b583          	ld	a1,-322(a1) # ffffffffc02061c0 <error_string+0x38>
ffffffffc020330a:	02b70733          	mul	a4,a4,a1
ffffffffc020330e:	00003617          	auipc	a2,0x3
ffffffffc0203312:	eba63603          	ld	a2,-326(a2) # ffffffffc02061c8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0203316:	0000e697          	auipc	a3,0xe
ffffffffc020331a:	20a6b683          	ld	a3,522(a3) # ffffffffc0211520 <npage>
ffffffffc020331e:	06b2                	slli	a3,a3,0xc
ffffffffc0203320:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203322:	0732                	slli	a4,a4,0xc
ffffffffc0203324:	28d77b63          	bgeu	a4,a3,ffffffffc02035ba <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203328:	40f98733          	sub	a4,s3,a5
ffffffffc020332c:	870d                	srai	a4,a4,0x3
ffffffffc020332e:	02b70733          	mul	a4,a4,a1
ffffffffc0203332:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203334:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0203336:	4cd77263          	bgeu	a4,a3,ffffffffc02037fa <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020333a:	40f507b3          	sub	a5,a0,a5
ffffffffc020333e:	878d                	srai	a5,a5,0x3
ffffffffc0203340:	02b787b3          	mul	a5,a5,a1
ffffffffc0203344:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203346:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0203348:	30d7f963          	bgeu	a5,a3,ffffffffc020365a <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc020334c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020334e:	00043c03          	ld	s8,0(s0)
ffffffffc0203352:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0203356:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020335a:	e400                	sd	s0,8(s0)
ffffffffc020335c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020335e:	0000e797          	auipc	a5,0xe
ffffffffc0203362:	d807a923          	sw	zero,-622(a5) # ffffffffc02110f0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0203366:	f82fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020336a:	2c051863          	bnez	a0,ffffffffc020363a <default_check+0x3d6>
    free_page(p0);
ffffffffc020336e:	4585                	li	a1,1
ffffffffc0203370:	8552                	mv	a0,s4
ffffffffc0203372:	809fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    free_page(p1);
ffffffffc0203376:	4585                	li	a1,1
ffffffffc0203378:	854e                	mv	a0,s3
ffffffffc020337a:	801fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    free_page(p2);
ffffffffc020337e:	4585                	li	a1,1
ffffffffc0203380:	8556                	mv	a0,s5
ffffffffc0203382:	ff8fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    assert(nr_free == 3);
ffffffffc0203386:	4818                	lw	a4,16(s0)
ffffffffc0203388:	478d                	li	a5,3
ffffffffc020338a:	28f71863          	bne	a4,a5,ffffffffc020361a <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020338e:	4505                	li	a0,1
ffffffffc0203390:	f58fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0203394:	89aa                	mv	s3,a0
ffffffffc0203396:	26050263          	beqz	a0,ffffffffc02035fa <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020339a:	4505                	li	a0,1
ffffffffc020339c:	f4cfd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02033a0:	8aaa                	mv	s5,a0
ffffffffc02033a2:	3a050c63          	beqz	a0,ffffffffc020375a <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02033a6:	4505                	li	a0,1
ffffffffc02033a8:	f40fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02033ac:	8a2a                	mv	s4,a0
ffffffffc02033ae:	38050663          	beqz	a0,ffffffffc020373a <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc02033b2:	4505                	li	a0,1
ffffffffc02033b4:	f34fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02033b8:	36051163          	bnez	a0,ffffffffc020371a <default_check+0x4b6>
    free_page(p0);
ffffffffc02033bc:	4585                	li	a1,1
ffffffffc02033be:	854e                	mv	a0,s3
ffffffffc02033c0:	fbafd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02033c4:	641c                	ld	a5,8(s0)
ffffffffc02033c6:	20878a63          	beq	a5,s0,ffffffffc02035da <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc02033ca:	4505                	li	a0,1
ffffffffc02033cc:	f1cfd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02033d0:	30a99563          	bne	s3,a0,ffffffffc02036da <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc02033d4:	4505                	li	a0,1
ffffffffc02033d6:	f12fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02033da:	2e051063          	bnez	a0,ffffffffc02036ba <default_check+0x456>
    assert(nr_free == 0);
ffffffffc02033de:	481c                	lw	a5,16(s0)
ffffffffc02033e0:	2a079d63          	bnez	a5,ffffffffc020369a <default_check+0x436>
    free_page(p);
ffffffffc02033e4:	854e                	mv	a0,s3
ffffffffc02033e6:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02033e8:	01843023          	sd	s8,0(s0)
ffffffffc02033ec:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02033f0:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02033f4:	f86fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    free_page(p1);
ffffffffc02033f8:	4585                	li	a1,1
ffffffffc02033fa:	8556                	mv	a0,s5
ffffffffc02033fc:	f7efd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    free_page(p2);
ffffffffc0203400:	4585                	li	a1,1
ffffffffc0203402:	8552                	mv	a0,s4
ffffffffc0203404:	f76fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0203408:	4515                	li	a0,5
ffffffffc020340a:	edefd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020340e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0203410:	26050563          	beqz	a0,ffffffffc020367a <default_check+0x416>
ffffffffc0203414:	651c                	ld	a5,8(a0)
ffffffffc0203416:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0203418:	8b85                	andi	a5,a5,1
ffffffffc020341a:	54079063          	bnez	a5,ffffffffc020395a <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020341e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0203420:	00043b03          	ld	s6,0(s0)
ffffffffc0203424:	00843a83          	ld	s5,8(s0)
ffffffffc0203428:	e000                	sd	s0,0(s0)
ffffffffc020342a:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020342c:	ebcfd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0203430:	50051563          	bnez	a0,ffffffffc020393a <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0203434:	09098a13          	addi	s4,s3,144
ffffffffc0203438:	8552                	mv	a0,s4
ffffffffc020343a:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020343c:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0203440:	0000e797          	auipc	a5,0xe
ffffffffc0203444:	ca07a823          	sw	zero,-848(a5) # ffffffffc02110f0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0203448:	f32fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020344c:	4511                	li	a0,4
ffffffffc020344e:	e9afd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0203452:	4c051463          	bnez	a0,ffffffffc020391a <default_check+0x6b6>
ffffffffc0203456:	0989b783          	ld	a5,152(s3)
ffffffffc020345a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020345c:	8b85                	andi	a5,a5,1
ffffffffc020345e:	48078e63          	beqz	a5,ffffffffc02038fa <default_check+0x696>
ffffffffc0203462:	0a89a703          	lw	a4,168(s3)
ffffffffc0203466:	478d                	li	a5,3
ffffffffc0203468:	48f71963          	bne	a4,a5,ffffffffc02038fa <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020346c:	450d                	li	a0,3
ffffffffc020346e:	e7afd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0203472:	8c2a                	mv	s8,a0
ffffffffc0203474:	46050363          	beqz	a0,ffffffffc02038da <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0203478:	4505                	li	a0,1
ffffffffc020347a:	e6efd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc020347e:	42051e63          	bnez	a0,ffffffffc02038ba <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0203482:	418a1c63          	bne	s4,s8,ffffffffc020389a <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0203486:	4585                	li	a1,1
ffffffffc0203488:	854e                	mv	a0,s3
ffffffffc020348a:	ef0fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    free_pages(p1, 3);
ffffffffc020348e:	458d                	li	a1,3
ffffffffc0203490:	8552                	mv	a0,s4
ffffffffc0203492:	ee8fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
ffffffffc0203496:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020349a:	04898c13          	addi	s8,s3,72
ffffffffc020349e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02034a0:	8b85                	andi	a5,a5,1
ffffffffc02034a2:	3c078c63          	beqz	a5,ffffffffc020387a <default_check+0x616>
ffffffffc02034a6:	0189a703          	lw	a4,24(s3)
ffffffffc02034aa:	4785                	li	a5,1
ffffffffc02034ac:	3cf71763          	bne	a4,a5,ffffffffc020387a <default_check+0x616>
ffffffffc02034b0:	008a3783          	ld	a5,8(s4)
ffffffffc02034b4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02034b6:	8b85                	andi	a5,a5,1
ffffffffc02034b8:	3a078163          	beqz	a5,ffffffffc020385a <default_check+0x5f6>
ffffffffc02034bc:	018a2703          	lw	a4,24(s4)
ffffffffc02034c0:	478d                	li	a5,3
ffffffffc02034c2:	38f71c63          	bne	a4,a5,ffffffffc020385a <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02034c6:	4505                	li	a0,1
ffffffffc02034c8:	e20fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02034cc:	36a99763          	bne	s3,a0,ffffffffc020383a <default_check+0x5d6>
    free_page(p0);
ffffffffc02034d0:	4585                	li	a1,1
ffffffffc02034d2:	ea8fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02034d6:	4509                	li	a0,2
ffffffffc02034d8:	e10fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02034dc:	32aa1f63          	bne	s4,a0,ffffffffc020381a <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc02034e0:	4589                	li	a1,2
ffffffffc02034e2:	e98fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    free_page(p2);
ffffffffc02034e6:	4585                	li	a1,1
ffffffffc02034e8:	8562                	mv	a0,s8
ffffffffc02034ea:	e90fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02034ee:	4515                	li	a0,5
ffffffffc02034f0:	df8fd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc02034f4:	89aa                	mv	s3,a0
ffffffffc02034f6:	48050263          	beqz	a0,ffffffffc020397a <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc02034fa:	4505                	li	a0,1
ffffffffc02034fc:	decfd0ef          	jal	ra,ffffffffc0200ae8 <alloc_pages>
ffffffffc0203500:	2c051d63          	bnez	a0,ffffffffc02037da <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0203504:	481c                	lw	a5,16(s0)
ffffffffc0203506:	2a079a63          	bnez	a5,ffffffffc02037ba <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020350a:	4595                	li	a1,5
ffffffffc020350c:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020350e:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0203512:	01643023          	sd	s6,0(s0)
ffffffffc0203516:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020351a:	e60fd0ef          	jal	ra,ffffffffc0200b7a <free_pages>
    return listelm->next;
ffffffffc020351e:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203520:	00878963          	beq	a5,s0,ffffffffc0203532 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0203524:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203528:	679c                	ld	a5,8(a5)
ffffffffc020352a:	397d                	addiw	s2,s2,-1
ffffffffc020352c:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020352e:	fe879be3          	bne	a5,s0,ffffffffc0203524 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0203532:	26091463          	bnez	s2,ffffffffc020379a <default_check+0x536>
    assert(total == 0);
ffffffffc0203536:	46049263          	bnez	s1,ffffffffc020399a <default_check+0x736>
}
ffffffffc020353a:	60a6                	ld	ra,72(sp)
ffffffffc020353c:	6406                	ld	s0,64(sp)
ffffffffc020353e:	74e2                	ld	s1,56(sp)
ffffffffc0203540:	7942                	ld	s2,48(sp)
ffffffffc0203542:	79a2                	ld	s3,40(sp)
ffffffffc0203544:	7a02                	ld	s4,32(sp)
ffffffffc0203546:	6ae2                	ld	s5,24(sp)
ffffffffc0203548:	6b42                	ld	s6,16(sp)
ffffffffc020354a:	6ba2                	ld	s7,8(sp)
ffffffffc020354c:	6c02                	ld	s8,0(sp)
ffffffffc020354e:	6161                	addi	sp,sp,80
ffffffffc0203550:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203552:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0203554:	4481                	li	s1,0
ffffffffc0203556:	4901                	li	s2,0
ffffffffc0203558:	b3b9                	j	ffffffffc02032a6 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020355a:	00002697          	auipc	a3,0x2
ffffffffc020355e:	1f668693          	addi	a3,a3,502 # ffffffffc0205750 <commands+0x1100>
ffffffffc0203562:	00002617          	auipc	a2,0x2
ffffffffc0203566:	97660613          	addi	a2,a2,-1674 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020356a:	0f000593          	li	a1,240
ffffffffc020356e:	00002517          	auipc	a0,0x2
ffffffffc0203572:	61250513          	addi	a0,a0,1554 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203576:	b8dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020357a:	00002697          	auipc	a3,0x2
ffffffffc020357e:	67e68693          	addi	a3,a3,1662 # ffffffffc0205bf8 <commands+0x15a8>
ffffffffc0203582:	00002617          	auipc	a2,0x2
ffffffffc0203586:	95660613          	addi	a2,a2,-1706 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020358a:	0bd00593          	li	a1,189
ffffffffc020358e:	00002517          	auipc	a0,0x2
ffffffffc0203592:	5f250513          	addi	a0,a0,1522 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203596:	b6dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020359a:	00002697          	auipc	a3,0x2
ffffffffc020359e:	68668693          	addi	a3,a3,1670 # ffffffffc0205c20 <commands+0x15d0>
ffffffffc02035a2:	00002617          	auipc	a2,0x2
ffffffffc02035a6:	93660613          	addi	a2,a2,-1738 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02035aa:	0be00593          	li	a1,190
ffffffffc02035ae:	00002517          	auipc	a0,0x2
ffffffffc02035b2:	5d250513          	addi	a0,a0,1490 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02035b6:	b4dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02035ba:	00002697          	auipc	a3,0x2
ffffffffc02035be:	6a668693          	addi	a3,a3,1702 # ffffffffc0205c60 <commands+0x1610>
ffffffffc02035c2:	00002617          	auipc	a2,0x2
ffffffffc02035c6:	91660613          	addi	a2,a2,-1770 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02035ca:	0c000593          	li	a1,192
ffffffffc02035ce:	00002517          	auipc	a0,0x2
ffffffffc02035d2:	5b250513          	addi	a0,a0,1458 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02035d6:	b2dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02035da:	00002697          	auipc	a3,0x2
ffffffffc02035de:	70e68693          	addi	a3,a3,1806 # ffffffffc0205ce8 <commands+0x1698>
ffffffffc02035e2:	00002617          	auipc	a2,0x2
ffffffffc02035e6:	8f660613          	addi	a2,a2,-1802 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02035ea:	0d900593          	li	a1,217
ffffffffc02035ee:	00002517          	auipc	a0,0x2
ffffffffc02035f2:	59250513          	addi	a0,a0,1426 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02035f6:	b0dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02035fa:	00002697          	auipc	a3,0x2
ffffffffc02035fe:	59e68693          	addi	a3,a3,1438 # ffffffffc0205b98 <commands+0x1548>
ffffffffc0203602:	00002617          	auipc	a2,0x2
ffffffffc0203606:	8d660613          	addi	a2,a2,-1834 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020360a:	0d200593          	li	a1,210
ffffffffc020360e:	00002517          	auipc	a0,0x2
ffffffffc0203612:	57250513          	addi	a0,a0,1394 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203616:	aedfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 3);
ffffffffc020361a:	00002697          	auipc	a3,0x2
ffffffffc020361e:	6be68693          	addi	a3,a3,1726 # ffffffffc0205cd8 <commands+0x1688>
ffffffffc0203622:	00002617          	auipc	a2,0x2
ffffffffc0203626:	8b660613          	addi	a2,a2,-1866 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020362a:	0d000593          	li	a1,208
ffffffffc020362e:	00002517          	auipc	a0,0x2
ffffffffc0203632:	55250513          	addi	a0,a0,1362 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203636:	acdfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020363a:	00002697          	auipc	a3,0x2
ffffffffc020363e:	68668693          	addi	a3,a3,1670 # ffffffffc0205cc0 <commands+0x1670>
ffffffffc0203642:	00002617          	auipc	a2,0x2
ffffffffc0203646:	89660613          	addi	a2,a2,-1898 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020364a:	0cb00593          	li	a1,203
ffffffffc020364e:	00002517          	auipc	a0,0x2
ffffffffc0203652:	53250513          	addi	a0,a0,1330 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203656:	aadfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020365a:	00002697          	auipc	a3,0x2
ffffffffc020365e:	64668693          	addi	a3,a3,1606 # ffffffffc0205ca0 <commands+0x1650>
ffffffffc0203662:	00002617          	auipc	a2,0x2
ffffffffc0203666:	87660613          	addi	a2,a2,-1930 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020366a:	0c200593          	li	a1,194
ffffffffc020366e:	00002517          	auipc	a0,0x2
ffffffffc0203672:	51250513          	addi	a0,a0,1298 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203676:	a8dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 != NULL);
ffffffffc020367a:	00002697          	auipc	a3,0x2
ffffffffc020367e:	6a668693          	addi	a3,a3,1702 # ffffffffc0205d20 <commands+0x16d0>
ffffffffc0203682:	00002617          	auipc	a2,0x2
ffffffffc0203686:	85660613          	addi	a2,a2,-1962 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020368a:	0f800593          	li	a1,248
ffffffffc020368e:	00002517          	auipc	a0,0x2
ffffffffc0203692:	4f250513          	addi	a0,a0,1266 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203696:	a6dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 0);
ffffffffc020369a:	00002697          	auipc	a3,0x2
ffffffffc020369e:	26668693          	addi	a3,a3,614 # ffffffffc0205900 <commands+0x12b0>
ffffffffc02036a2:	00002617          	auipc	a2,0x2
ffffffffc02036a6:	83660613          	addi	a2,a2,-1994 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02036aa:	0df00593          	li	a1,223
ffffffffc02036ae:	00002517          	auipc	a0,0x2
ffffffffc02036b2:	4d250513          	addi	a0,a0,1234 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02036b6:	a4dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02036ba:	00002697          	auipc	a3,0x2
ffffffffc02036be:	60668693          	addi	a3,a3,1542 # ffffffffc0205cc0 <commands+0x1670>
ffffffffc02036c2:	00002617          	auipc	a2,0x2
ffffffffc02036c6:	81660613          	addi	a2,a2,-2026 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02036ca:	0dd00593          	li	a1,221
ffffffffc02036ce:	00002517          	auipc	a0,0x2
ffffffffc02036d2:	4b250513          	addi	a0,a0,1202 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02036d6:	a2dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02036da:	00002697          	auipc	a3,0x2
ffffffffc02036de:	62668693          	addi	a3,a3,1574 # ffffffffc0205d00 <commands+0x16b0>
ffffffffc02036e2:	00001617          	auipc	a2,0x1
ffffffffc02036e6:	7f660613          	addi	a2,a2,2038 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02036ea:	0dc00593          	li	a1,220
ffffffffc02036ee:	00002517          	auipc	a0,0x2
ffffffffc02036f2:	49250513          	addi	a0,a0,1170 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02036f6:	a0dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02036fa:	00002697          	auipc	a3,0x2
ffffffffc02036fe:	49e68693          	addi	a3,a3,1182 # ffffffffc0205b98 <commands+0x1548>
ffffffffc0203702:	00001617          	auipc	a2,0x1
ffffffffc0203706:	7d660613          	addi	a2,a2,2006 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020370a:	0b900593          	li	a1,185
ffffffffc020370e:	00002517          	auipc	a0,0x2
ffffffffc0203712:	47250513          	addi	a0,a0,1138 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203716:	9edfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020371a:	00002697          	auipc	a3,0x2
ffffffffc020371e:	5a668693          	addi	a3,a3,1446 # ffffffffc0205cc0 <commands+0x1670>
ffffffffc0203722:	00001617          	auipc	a2,0x1
ffffffffc0203726:	7b660613          	addi	a2,a2,1974 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020372a:	0d600593          	li	a1,214
ffffffffc020372e:	00002517          	auipc	a0,0x2
ffffffffc0203732:	45250513          	addi	a0,a0,1106 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203736:	9cdfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020373a:	00002697          	auipc	a3,0x2
ffffffffc020373e:	49e68693          	addi	a3,a3,1182 # ffffffffc0205bd8 <commands+0x1588>
ffffffffc0203742:	00001617          	auipc	a2,0x1
ffffffffc0203746:	79660613          	addi	a2,a2,1942 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020374a:	0d400593          	li	a1,212
ffffffffc020374e:	00002517          	auipc	a0,0x2
ffffffffc0203752:	43250513          	addi	a0,a0,1074 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203756:	9adfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020375a:	00002697          	auipc	a3,0x2
ffffffffc020375e:	45e68693          	addi	a3,a3,1118 # ffffffffc0205bb8 <commands+0x1568>
ffffffffc0203762:	00001617          	auipc	a2,0x1
ffffffffc0203766:	77660613          	addi	a2,a2,1910 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020376a:	0d300593          	li	a1,211
ffffffffc020376e:	00002517          	auipc	a0,0x2
ffffffffc0203772:	41250513          	addi	a0,a0,1042 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203776:	98dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020377a:	00002697          	auipc	a3,0x2
ffffffffc020377e:	45e68693          	addi	a3,a3,1118 # ffffffffc0205bd8 <commands+0x1588>
ffffffffc0203782:	00001617          	auipc	a2,0x1
ffffffffc0203786:	75660613          	addi	a2,a2,1878 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020378a:	0bb00593          	li	a1,187
ffffffffc020378e:	00002517          	auipc	a0,0x2
ffffffffc0203792:	3f250513          	addi	a0,a0,1010 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203796:	96dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(count == 0);
ffffffffc020379a:	00002697          	auipc	a3,0x2
ffffffffc020379e:	6d668693          	addi	a3,a3,1750 # ffffffffc0205e70 <commands+0x1820>
ffffffffc02037a2:	00001617          	auipc	a2,0x1
ffffffffc02037a6:	73660613          	addi	a2,a2,1846 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02037aa:	12500593          	li	a1,293
ffffffffc02037ae:	00002517          	auipc	a0,0x2
ffffffffc02037b2:	3d250513          	addi	a0,a0,978 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02037b6:	94dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 0);
ffffffffc02037ba:	00002697          	auipc	a3,0x2
ffffffffc02037be:	14668693          	addi	a3,a3,326 # ffffffffc0205900 <commands+0x12b0>
ffffffffc02037c2:	00001617          	auipc	a2,0x1
ffffffffc02037c6:	71660613          	addi	a2,a2,1814 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02037ca:	11a00593          	li	a1,282
ffffffffc02037ce:	00002517          	auipc	a0,0x2
ffffffffc02037d2:	3b250513          	addi	a0,a0,946 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02037d6:	92dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02037da:	00002697          	auipc	a3,0x2
ffffffffc02037de:	4e668693          	addi	a3,a3,1254 # ffffffffc0205cc0 <commands+0x1670>
ffffffffc02037e2:	00001617          	auipc	a2,0x1
ffffffffc02037e6:	6f660613          	addi	a2,a2,1782 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02037ea:	11800593          	li	a1,280
ffffffffc02037ee:	00002517          	auipc	a0,0x2
ffffffffc02037f2:	39250513          	addi	a0,a0,914 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02037f6:	90dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02037fa:	00002697          	auipc	a3,0x2
ffffffffc02037fe:	48668693          	addi	a3,a3,1158 # ffffffffc0205c80 <commands+0x1630>
ffffffffc0203802:	00001617          	auipc	a2,0x1
ffffffffc0203806:	6d660613          	addi	a2,a2,1750 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020380a:	0c100593          	li	a1,193
ffffffffc020380e:	00002517          	auipc	a0,0x2
ffffffffc0203812:	37250513          	addi	a0,a0,882 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203816:	8edfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020381a:	00002697          	auipc	a3,0x2
ffffffffc020381e:	61668693          	addi	a3,a3,1558 # ffffffffc0205e30 <commands+0x17e0>
ffffffffc0203822:	00001617          	auipc	a2,0x1
ffffffffc0203826:	6b660613          	addi	a2,a2,1718 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020382a:	11200593          	li	a1,274
ffffffffc020382e:	00002517          	auipc	a0,0x2
ffffffffc0203832:	35250513          	addi	a0,a0,850 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203836:	8cdfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020383a:	00002697          	auipc	a3,0x2
ffffffffc020383e:	5d668693          	addi	a3,a3,1494 # ffffffffc0205e10 <commands+0x17c0>
ffffffffc0203842:	00001617          	auipc	a2,0x1
ffffffffc0203846:	69660613          	addi	a2,a2,1686 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020384a:	11000593          	li	a1,272
ffffffffc020384e:	00002517          	auipc	a0,0x2
ffffffffc0203852:	33250513          	addi	a0,a0,818 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203856:	8adfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020385a:	00002697          	auipc	a3,0x2
ffffffffc020385e:	58e68693          	addi	a3,a3,1422 # ffffffffc0205de8 <commands+0x1798>
ffffffffc0203862:	00001617          	auipc	a2,0x1
ffffffffc0203866:	67660613          	addi	a2,a2,1654 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020386a:	10e00593          	li	a1,270
ffffffffc020386e:	00002517          	auipc	a0,0x2
ffffffffc0203872:	31250513          	addi	a0,a0,786 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203876:	88dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020387a:	00002697          	auipc	a3,0x2
ffffffffc020387e:	54668693          	addi	a3,a3,1350 # ffffffffc0205dc0 <commands+0x1770>
ffffffffc0203882:	00001617          	auipc	a2,0x1
ffffffffc0203886:	65660613          	addi	a2,a2,1622 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020388a:	10d00593          	li	a1,269
ffffffffc020388e:	00002517          	auipc	a0,0x2
ffffffffc0203892:	2f250513          	addi	a0,a0,754 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203896:	86dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020389a:	00002697          	auipc	a3,0x2
ffffffffc020389e:	51668693          	addi	a3,a3,1302 # ffffffffc0205db0 <commands+0x1760>
ffffffffc02038a2:	00001617          	auipc	a2,0x1
ffffffffc02038a6:	63660613          	addi	a2,a2,1590 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02038aa:	10800593          	li	a1,264
ffffffffc02038ae:	00002517          	auipc	a0,0x2
ffffffffc02038b2:	2d250513          	addi	a0,a0,722 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02038b6:	84dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02038ba:	00002697          	auipc	a3,0x2
ffffffffc02038be:	40668693          	addi	a3,a3,1030 # ffffffffc0205cc0 <commands+0x1670>
ffffffffc02038c2:	00001617          	auipc	a2,0x1
ffffffffc02038c6:	61660613          	addi	a2,a2,1558 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02038ca:	10700593          	li	a1,263
ffffffffc02038ce:	00002517          	auipc	a0,0x2
ffffffffc02038d2:	2b250513          	addi	a0,a0,690 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02038d6:	82dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02038da:	00002697          	auipc	a3,0x2
ffffffffc02038de:	4b668693          	addi	a3,a3,1206 # ffffffffc0205d90 <commands+0x1740>
ffffffffc02038e2:	00001617          	auipc	a2,0x1
ffffffffc02038e6:	5f660613          	addi	a2,a2,1526 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02038ea:	10600593          	li	a1,262
ffffffffc02038ee:	00002517          	auipc	a0,0x2
ffffffffc02038f2:	29250513          	addi	a0,a0,658 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02038f6:	80dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02038fa:	00002697          	auipc	a3,0x2
ffffffffc02038fe:	46668693          	addi	a3,a3,1126 # ffffffffc0205d60 <commands+0x1710>
ffffffffc0203902:	00001617          	auipc	a2,0x1
ffffffffc0203906:	5d660613          	addi	a2,a2,1494 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020390a:	10500593          	li	a1,261
ffffffffc020390e:	00002517          	auipc	a0,0x2
ffffffffc0203912:	27250513          	addi	a0,a0,626 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203916:	fecfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020391a:	00002697          	auipc	a3,0x2
ffffffffc020391e:	42e68693          	addi	a3,a3,1070 # ffffffffc0205d48 <commands+0x16f8>
ffffffffc0203922:	00001617          	auipc	a2,0x1
ffffffffc0203926:	5b660613          	addi	a2,a2,1462 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020392a:	10400593          	li	a1,260
ffffffffc020392e:	00002517          	auipc	a0,0x2
ffffffffc0203932:	25250513          	addi	a0,a0,594 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203936:	fccfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020393a:	00002697          	auipc	a3,0x2
ffffffffc020393e:	38668693          	addi	a3,a3,902 # ffffffffc0205cc0 <commands+0x1670>
ffffffffc0203942:	00001617          	auipc	a2,0x1
ffffffffc0203946:	59660613          	addi	a2,a2,1430 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020394a:	0fe00593          	li	a1,254
ffffffffc020394e:	00002517          	auipc	a0,0x2
ffffffffc0203952:	23250513          	addi	a0,a0,562 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203956:	facfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(!PageProperty(p0));
ffffffffc020395a:	00002697          	auipc	a3,0x2
ffffffffc020395e:	3d668693          	addi	a3,a3,982 # ffffffffc0205d30 <commands+0x16e0>
ffffffffc0203962:	00001617          	auipc	a2,0x1
ffffffffc0203966:	57660613          	addi	a2,a2,1398 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020396a:	0f900593          	li	a1,249
ffffffffc020396e:	00002517          	auipc	a0,0x2
ffffffffc0203972:	21250513          	addi	a0,a0,530 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203976:	f8cfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020397a:	00002697          	auipc	a3,0x2
ffffffffc020397e:	4d668693          	addi	a3,a3,1238 # ffffffffc0205e50 <commands+0x1800>
ffffffffc0203982:	00001617          	auipc	a2,0x1
ffffffffc0203986:	55660613          	addi	a2,a2,1366 # ffffffffc0204ed8 <commands+0x888>
ffffffffc020398a:	11700593          	li	a1,279
ffffffffc020398e:	00002517          	auipc	a0,0x2
ffffffffc0203992:	1f250513          	addi	a0,a0,498 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203996:	f6cfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == 0);
ffffffffc020399a:	00002697          	auipc	a3,0x2
ffffffffc020399e:	4e668693          	addi	a3,a3,1254 # ffffffffc0205e80 <commands+0x1830>
ffffffffc02039a2:	00001617          	auipc	a2,0x1
ffffffffc02039a6:	53660613          	addi	a2,a2,1334 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02039aa:	12600593          	li	a1,294
ffffffffc02039ae:	00002517          	auipc	a0,0x2
ffffffffc02039b2:	1d250513          	addi	a0,a0,466 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02039b6:	f4cfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == nr_free_pages());
ffffffffc02039ba:	00002697          	auipc	a3,0x2
ffffffffc02039be:	da668693          	addi	a3,a3,-602 # ffffffffc0205760 <commands+0x1110>
ffffffffc02039c2:	00001617          	auipc	a2,0x1
ffffffffc02039c6:	51660613          	addi	a2,a2,1302 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02039ca:	0f300593          	li	a1,243
ffffffffc02039ce:	00002517          	auipc	a0,0x2
ffffffffc02039d2:	1b250513          	addi	a0,a0,434 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02039d6:	f2cfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02039da:	00002697          	auipc	a3,0x2
ffffffffc02039de:	1de68693          	addi	a3,a3,478 # ffffffffc0205bb8 <commands+0x1568>
ffffffffc02039e2:	00001617          	auipc	a2,0x1
ffffffffc02039e6:	4f660613          	addi	a2,a2,1270 # ffffffffc0204ed8 <commands+0x888>
ffffffffc02039ea:	0ba00593          	li	a1,186
ffffffffc02039ee:	00002517          	auipc	a0,0x2
ffffffffc02039f2:	19250513          	addi	a0,a0,402 # ffffffffc0205b80 <commands+0x1530>
ffffffffc02039f6:	f0cfc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02039fa <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02039fa:	1141                	addi	sp,sp,-16
ffffffffc02039fc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02039fe:	14058a63          	beqz	a1,ffffffffc0203b52 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0203a02:	00359693          	slli	a3,a1,0x3
ffffffffc0203a06:	96ae                	add	a3,a3,a1
ffffffffc0203a08:	068e                	slli	a3,a3,0x3
ffffffffc0203a0a:	96aa                	add	a3,a3,a0
ffffffffc0203a0c:	87aa                	mv	a5,a0
ffffffffc0203a0e:	02d50263          	beq	a0,a3,ffffffffc0203a32 <default_free_pages+0x38>
ffffffffc0203a12:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203a14:	8b05                	andi	a4,a4,1
ffffffffc0203a16:	10071e63          	bnez	a4,ffffffffc0203b32 <default_free_pages+0x138>
ffffffffc0203a1a:	6798                	ld	a4,8(a5)
ffffffffc0203a1c:	8b09                	andi	a4,a4,2
ffffffffc0203a1e:	10071a63          	bnez	a4,ffffffffc0203b32 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0203a22:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0203a26:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0203a2a:	04878793          	addi	a5,a5,72
ffffffffc0203a2e:	fed792e3          	bne	a5,a3,ffffffffc0203a12 <default_free_pages+0x18>
    base->property = n;
ffffffffc0203a32:	2581                	sext.w	a1,a1
ffffffffc0203a34:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0203a36:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203a3a:	4789                	li	a5,2
ffffffffc0203a3c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0203a40:	0000d697          	auipc	a3,0xd
ffffffffc0203a44:	6a068693          	addi	a3,a3,1696 # ffffffffc02110e0 <free_area>
ffffffffc0203a48:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203a4a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0203a4c:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc0203a50:	9db9                	addw	a1,a1,a4
ffffffffc0203a52:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0203a54:	0ad78863          	beq	a5,a3,ffffffffc0203b04 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0203a58:	fe078713          	addi	a4,a5,-32
ffffffffc0203a5c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203a60:	4581                	li	a1,0
            if (base < page) {
ffffffffc0203a62:	00e56a63          	bltu	a0,a4,ffffffffc0203a76 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0203a66:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203a68:	06d70263          	beq	a4,a3,ffffffffc0203acc <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0203a6c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0203a6e:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0203a72:	fee57ae3          	bgeu	a0,a4,ffffffffc0203a66 <default_free_pages+0x6c>
ffffffffc0203a76:	c199                	beqz	a1,ffffffffc0203a7c <default_free_pages+0x82>
ffffffffc0203a78:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203a7c:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203a7e:	e390                	sd	a2,0(a5)
ffffffffc0203a80:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203a82:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203a84:	f118                	sd	a4,32(a0)
    if (le != &free_list) {
ffffffffc0203a86:	02d70063          	beq	a4,a3,ffffffffc0203aa6 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0203a8a:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0203a8e:	fe070593          	addi	a1,a4,-32
        if (p + p->property == base) {
ffffffffc0203a92:	02081613          	slli	a2,a6,0x20
ffffffffc0203a96:	9201                	srli	a2,a2,0x20
ffffffffc0203a98:	00361793          	slli	a5,a2,0x3
ffffffffc0203a9c:	97b2                	add	a5,a5,a2
ffffffffc0203a9e:	078e                	slli	a5,a5,0x3
ffffffffc0203aa0:	97ae                	add	a5,a5,a1
ffffffffc0203aa2:	02f50f63          	beq	a0,a5,ffffffffc0203ae0 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0203aa6:	7518                	ld	a4,40(a0)
    if (le != &free_list) {
ffffffffc0203aa8:	00d70f63          	beq	a4,a3,ffffffffc0203ac6 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0203aac:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc0203aae:	fe070693          	addi	a3,a4,-32
        if (base + base->property == p) {
ffffffffc0203ab2:	02059613          	slli	a2,a1,0x20
ffffffffc0203ab6:	9201                	srli	a2,a2,0x20
ffffffffc0203ab8:	00361793          	slli	a5,a2,0x3
ffffffffc0203abc:	97b2                	add	a5,a5,a2
ffffffffc0203abe:	078e                	slli	a5,a5,0x3
ffffffffc0203ac0:	97aa                	add	a5,a5,a0
ffffffffc0203ac2:	04f68863          	beq	a3,a5,ffffffffc0203b12 <default_free_pages+0x118>
}
ffffffffc0203ac6:	60a2                	ld	ra,8(sp)
ffffffffc0203ac8:	0141                	addi	sp,sp,16
ffffffffc0203aca:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203acc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203ace:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0203ad0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203ad2:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203ad4:	02d70563          	beq	a4,a3,ffffffffc0203afe <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0203ad8:	8832                	mv	a6,a2
ffffffffc0203ada:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0203adc:	87ba                	mv	a5,a4
ffffffffc0203ade:	bf41                	j	ffffffffc0203a6e <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0203ae0:	4d1c                	lw	a5,24(a0)
ffffffffc0203ae2:	0107883b          	addw	a6,a5,a6
ffffffffc0203ae6:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203aea:	57f5                	li	a5,-3
ffffffffc0203aec:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203af0:	7110                	ld	a2,32(a0)
ffffffffc0203af2:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc0203af4:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc0203af6:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0203af8:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0203afa:	e390                	sd	a2,0(a5)
ffffffffc0203afc:	b775                	j	ffffffffc0203aa8 <default_free_pages+0xae>
ffffffffc0203afe:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203b00:	873e                	mv	a4,a5
ffffffffc0203b02:	b761                	j	ffffffffc0203a8a <default_free_pages+0x90>
}
ffffffffc0203b04:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203b06:	e390                	sd	a2,0(a5)
ffffffffc0203b08:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203b0a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203b0c:	f11c                	sd	a5,32(a0)
ffffffffc0203b0e:	0141                	addi	sp,sp,16
ffffffffc0203b10:	8082                	ret
            base->property += p->property;
ffffffffc0203b12:	ff872783          	lw	a5,-8(a4)
ffffffffc0203b16:	fe870693          	addi	a3,a4,-24
ffffffffc0203b1a:	9dbd                	addw	a1,a1,a5
ffffffffc0203b1c:	cd0c                	sw	a1,24(a0)
ffffffffc0203b1e:	57f5                	li	a5,-3
ffffffffc0203b20:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203b24:	6314                	ld	a3,0(a4)
ffffffffc0203b26:	671c                	ld	a5,8(a4)
}
ffffffffc0203b28:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203b2a:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0203b2c:	e394                	sd	a3,0(a5)
ffffffffc0203b2e:	0141                	addi	sp,sp,16
ffffffffc0203b30:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203b32:	00002697          	auipc	a3,0x2
ffffffffc0203b36:	36668693          	addi	a3,a3,870 # ffffffffc0205e98 <commands+0x1848>
ffffffffc0203b3a:	00001617          	auipc	a2,0x1
ffffffffc0203b3e:	39e60613          	addi	a2,a2,926 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203b42:	08300593          	li	a1,131
ffffffffc0203b46:	00002517          	auipc	a0,0x2
ffffffffc0203b4a:	03a50513          	addi	a0,a0,58 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203b4e:	db4fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0);
ffffffffc0203b52:	00002697          	auipc	a3,0x2
ffffffffc0203b56:	33e68693          	addi	a3,a3,830 # ffffffffc0205e90 <commands+0x1840>
ffffffffc0203b5a:	00001617          	auipc	a2,0x1
ffffffffc0203b5e:	37e60613          	addi	a2,a2,894 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203b62:	08000593          	li	a1,128
ffffffffc0203b66:	00002517          	auipc	a0,0x2
ffffffffc0203b6a:	01a50513          	addi	a0,a0,26 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203b6e:	d94fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203b72 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203b72:	c959                	beqz	a0,ffffffffc0203c08 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0203b74:	0000d597          	auipc	a1,0xd
ffffffffc0203b78:	56c58593          	addi	a1,a1,1388 # ffffffffc02110e0 <free_area>
ffffffffc0203b7c:	0105a803          	lw	a6,16(a1)
ffffffffc0203b80:	862a                	mv	a2,a0
ffffffffc0203b82:	02081793          	slli	a5,a6,0x20
ffffffffc0203b86:	9381                	srli	a5,a5,0x20
ffffffffc0203b88:	00a7ee63          	bltu	a5,a0,ffffffffc0203ba4 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203b8c:	87ae                	mv	a5,a1
ffffffffc0203b8e:	a801                	j	ffffffffc0203b9e <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0203b90:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203b94:	02071693          	slli	a3,a4,0x20
ffffffffc0203b98:	9281                	srli	a3,a3,0x20
ffffffffc0203b9a:	00c6f763          	bgeu	a3,a2,ffffffffc0203ba8 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203b9e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203ba0:	feb798e3          	bne	a5,a1,ffffffffc0203b90 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0203ba4:	4501                	li	a0,0
}
ffffffffc0203ba6:	8082                	ret
    return listelm->prev;
ffffffffc0203ba8:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203bac:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0203bb0:	fe078513          	addi	a0,a5,-32
            p->property = page->property - n;
ffffffffc0203bb4:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0203bb8:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0203bbc:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0203bc0:	02d67b63          	bgeu	a2,a3,ffffffffc0203bf6 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0203bc4:	00361693          	slli	a3,a2,0x3
ffffffffc0203bc8:	96b2                	add	a3,a3,a2
ffffffffc0203bca:	068e                	slli	a3,a3,0x3
ffffffffc0203bcc:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0203bce:	41c7073b          	subw	a4,a4,t3
ffffffffc0203bd2:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203bd4:	00868613          	addi	a2,a3,8
ffffffffc0203bd8:	4709                	li	a4,2
ffffffffc0203bda:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203bde:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0203be2:	02068613          	addi	a2,a3,32
        nr_free -= n;
ffffffffc0203be6:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0203bea:	e310                	sd	a2,0(a4)
ffffffffc0203bec:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0203bf0:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc0203bf2:	0316b023          	sd	a7,32(a3)
ffffffffc0203bf6:	41c8083b          	subw	a6,a6,t3
ffffffffc0203bfa:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203bfe:	5775                	li	a4,-3
ffffffffc0203c00:	17a1                	addi	a5,a5,-24
ffffffffc0203c02:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0203c06:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0203c08:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203c0a:	00002697          	auipc	a3,0x2
ffffffffc0203c0e:	28668693          	addi	a3,a3,646 # ffffffffc0205e90 <commands+0x1840>
ffffffffc0203c12:	00001617          	auipc	a2,0x1
ffffffffc0203c16:	2c660613          	addi	a2,a2,710 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203c1a:	06200593          	li	a1,98
ffffffffc0203c1e:	00002517          	auipc	a0,0x2
ffffffffc0203c22:	f6250513          	addi	a0,a0,-158 # ffffffffc0205b80 <commands+0x1530>
default_alloc_pages(size_t n) {
ffffffffc0203c26:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203c28:	cdafc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203c2c <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0203c2c:	1141                	addi	sp,sp,-16
ffffffffc0203c2e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203c30:	c9e1                	beqz	a1,ffffffffc0203d00 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0203c32:	00359693          	slli	a3,a1,0x3
ffffffffc0203c36:	96ae                	add	a3,a3,a1
ffffffffc0203c38:	068e                	slli	a3,a3,0x3
ffffffffc0203c3a:	96aa                	add	a3,a3,a0
ffffffffc0203c3c:	87aa                	mv	a5,a0
ffffffffc0203c3e:	00d50f63          	beq	a0,a3,ffffffffc0203c5c <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203c42:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0203c44:	8b05                	andi	a4,a4,1
ffffffffc0203c46:	cf49                	beqz	a4,ffffffffc0203ce0 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0203c48:	0007ac23          	sw	zero,24(a5)
ffffffffc0203c4c:	0007b423          	sd	zero,8(a5)
ffffffffc0203c50:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0203c54:	04878793          	addi	a5,a5,72
ffffffffc0203c58:	fed795e3          	bne	a5,a3,ffffffffc0203c42 <default_init_memmap+0x16>
    base->property = n;
ffffffffc0203c5c:	2581                	sext.w	a1,a1
ffffffffc0203c5e:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203c60:	4789                	li	a5,2
ffffffffc0203c62:	00850713          	addi	a4,a0,8
ffffffffc0203c66:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203c6a:	0000d697          	auipc	a3,0xd
ffffffffc0203c6e:	47668693          	addi	a3,a3,1142 # ffffffffc02110e0 <free_area>
ffffffffc0203c72:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203c74:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0203c76:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc0203c7a:	9db9                	addw	a1,a1,a4
ffffffffc0203c7c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0203c7e:	04d78a63          	beq	a5,a3,ffffffffc0203cd2 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0203c82:	fe078713          	addi	a4,a5,-32
ffffffffc0203c86:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203c8a:	4581                	li	a1,0
            if (base < page) {
ffffffffc0203c8c:	00e56a63          	bltu	a0,a4,ffffffffc0203ca0 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0203c90:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203c92:	02d70263          	beq	a4,a3,ffffffffc0203cb6 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0203c96:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0203c98:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0203c9c:	fee57ae3          	bgeu	a0,a4,ffffffffc0203c90 <default_init_memmap+0x64>
ffffffffc0203ca0:	c199                	beqz	a1,ffffffffc0203ca6 <default_init_memmap+0x7a>
ffffffffc0203ca2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203ca6:	6398                	ld	a4,0(a5)
}
ffffffffc0203ca8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203caa:	e390                	sd	a2,0(a5)
ffffffffc0203cac:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203cae:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203cb0:	f118                	sd	a4,32(a0)
ffffffffc0203cb2:	0141                	addi	sp,sp,16
ffffffffc0203cb4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203cb6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203cb8:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0203cba:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0203cbc:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0203cbe:	00d70663          	beq	a4,a3,ffffffffc0203cca <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0203cc2:	8832                	mv	a6,a2
ffffffffc0203cc4:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0203cc6:	87ba                	mv	a5,a4
ffffffffc0203cc8:	bfc1                	j	ffffffffc0203c98 <default_init_memmap+0x6c>
}
ffffffffc0203cca:	60a2                	ld	ra,8(sp)
ffffffffc0203ccc:	e290                	sd	a2,0(a3)
ffffffffc0203cce:	0141                	addi	sp,sp,16
ffffffffc0203cd0:	8082                	ret
ffffffffc0203cd2:	60a2                	ld	ra,8(sp)
ffffffffc0203cd4:	e390                	sd	a2,0(a5)
ffffffffc0203cd6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203cd8:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0203cda:	f11c                	sd	a5,32(a0)
ffffffffc0203cdc:	0141                	addi	sp,sp,16
ffffffffc0203cde:	8082                	ret
        assert(PageReserved(p));
ffffffffc0203ce0:	00002697          	auipc	a3,0x2
ffffffffc0203ce4:	1e068693          	addi	a3,a3,480 # ffffffffc0205ec0 <commands+0x1870>
ffffffffc0203ce8:	00001617          	auipc	a2,0x1
ffffffffc0203cec:	1f060613          	addi	a2,a2,496 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203cf0:	04900593          	li	a1,73
ffffffffc0203cf4:	00002517          	auipc	a0,0x2
ffffffffc0203cf8:	e8c50513          	addi	a0,a0,-372 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203cfc:	c06fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0);
ffffffffc0203d00:	00002697          	auipc	a3,0x2
ffffffffc0203d04:	19068693          	addi	a3,a3,400 # ffffffffc0205e90 <commands+0x1840>
ffffffffc0203d08:	00001617          	auipc	a2,0x1
ffffffffc0203d0c:	1d060613          	addi	a2,a2,464 # ffffffffc0204ed8 <commands+0x888>
ffffffffc0203d10:	04600593          	li	a1,70
ffffffffc0203d14:	00002517          	auipc	a0,0x2
ffffffffc0203d18:	e6c50513          	addi	a0,a0,-404 # ffffffffc0205b80 <commands+0x1530>
ffffffffc0203d1c:	be6fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203d20 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) { //完成检查并初始化交换文件系统
ffffffffc0203d20:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);//确保交换文件系统操作合理
    if (!ide_device_valid(SWAP_DEV_NO)) {//是否有可用的IDE设备作为交换文件系统的后备存储设备
ffffffffc0203d22:	4505                	li	a0,1
swapfs_init(void) { //完成检查并初始化交换文件系统
ffffffffc0203d24:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {//是否有可用的IDE设备作为交换文件系统的后备存储设备
ffffffffc0203d26:	eacfc0ef          	jal	ra,ffffffffc02003d2 <ide_device_valid>
ffffffffc0203d2a:	cd01                	beqz	a0,ffffffffc0203d42 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);//可以使用的最大交换偏移量
ffffffffc0203d2c:	4505                	li	a0,1
ffffffffc0203d2e:	eaafc0ef          	jal	ra,ffffffffc02003d8 <ide_device_size>
}
ffffffffc0203d32:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);//可以使用的最大交换偏移量
ffffffffc0203d34:	810d                	srli	a0,a0,0x3
ffffffffc0203d36:	0000e797          	auipc	a5,0xe
ffffffffc0203d3a:	80a7bd23          	sd	a0,-2022(a5) # ffffffffc0211550 <max_swap_offset>
}
ffffffffc0203d3e:	0141                	addi	sp,sp,16
ffffffffc0203d40:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203d42:	00002617          	auipc	a2,0x2
ffffffffc0203d46:	1de60613          	addi	a2,a2,478 # ffffffffc0205f20 <default_pmm_manager+0x38>
ffffffffc0203d4a:	45b5                	li	a1,13
ffffffffc0203d4c:	00002517          	auipc	a0,0x2
ffffffffc0203d50:	1f450513          	addi	a0,a0,500 # ffffffffc0205f40 <default_pmm_manager+0x58>
ffffffffc0203d54:	baefc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203d58 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {//用于从交换文件系统中读取数据
ffffffffc0203d58:	1141                	addi	sp,sp,-16
ffffffffc0203d5a:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d5c:	00855793          	srli	a5,a0,0x8
ffffffffc0203d60:	c3a5                	beqz	a5,ffffffffc0203dc0 <swapfs_read+0x68>
ffffffffc0203d62:	0000d717          	auipc	a4,0xd
ffffffffc0203d66:	7ee73703          	ld	a4,2030(a4) # ffffffffc0211550 <max_swap_offset>
ffffffffc0203d6a:	04e7fb63          	bgeu	a5,a4,ffffffffc0203dc0 <swapfs_read+0x68>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d6e:	0000d617          	auipc	a2,0xd
ffffffffc0203d72:	7ba63603          	ld	a2,1978(a2) # ffffffffc0211528 <pages>
ffffffffc0203d76:	8d91                	sub	a1,a1,a2
ffffffffc0203d78:	4035d613          	srai	a2,a1,0x3
ffffffffc0203d7c:	00002597          	auipc	a1,0x2
ffffffffc0203d80:	4445b583          	ld	a1,1092(a1) # ffffffffc02061c0 <error_string+0x38>
ffffffffc0203d84:	02b60633          	mul	a2,a2,a1
ffffffffc0203d88:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d8c:	00002797          	auipc	a5,0x2
ffffffffc0203d90:	43c7b783          	ld	a5,1084(a5) # ffffffffc02061c8 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d94:	0000d717          	auipc	a4,0xd
ffffffffc0203d98:	78c73703          	ld	a4,1932(a4) # ffffffffc0211520 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d9c:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d9e:	00c61793          	slli	a5,a2,0xc
ffffffffc0203da2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203da4:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203da6:	02e7f963          	bgeu	a5,a4,ffffffffc0203dd8 <swapfs_read+0x80>
}
ffffffffc0203daa:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dac:	0000d797          	auipc	a5,0xd
ffffffffc0203db0:	78c7b783          	ld	a5,1932(a5) # ffffffffc0211538 <va_pa_offset>
ffffffffc0203db4:	46a1                	li	a3,8
ffffffffc0203db6:	963e                	add	a2,a2,a5
ffffffffc0203db8:	4505                	li	a0,1
}
ffffffffc0203dba:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dbc:	e22fc06f          	j	ffffffffc02003de <ide_read_secs>
ffffffffc0203dc0:	86aa                	mv	a3,a0
ffffffffc0203dc2:	00002617          	auipc	a2,0x2
ffffffffc0203dc6:	19660613          	addi	a2,a2,406 # ffffffffc0205f58 <default_pmm_manager+0x70>
ffffffffc0203dca:	45d1                	li	a1,20
ffffffffc0203dcc:	00002517          	auipc	a0,0x2
ffffffffc0203dd0:	17450513          	addi	a0,a0,372 # ffffffffc0205f40 <default_pmm_manager+0x58>
ffffffffc0203dd4:	b2efc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203dd8:	86b2                	mv	a3,a2
ffffffffc0203dda:	07100593          	li	a1,113
ffffffffc0203dde:	00001617          	auipc	a2,0x1
ffffffffc0203de2:	fd260613          	addi	a2,a2,-46 # ffffffffc0204db0 <commands+0x760>
ffffffffc0203de6:	00001517          	auipc	a0,0x1
ffffffffc0203dea:	f9250513          	addi	a0,a0,-110 # ffffffffc0204d78 <commands+0x728>
ffffffffc0203dee:	b14fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203df2 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {//用于向交换文件系统写入数据
ffffffffc0203df2:	1141                	addi	sp,sp,-16
ffffffffc0203df4:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203df6:	00855793          	srli	a5,a0,0x8
ffffffffc0203dfa:	c3a5                	beqz	a5,ffffffffc0203e5a <swapfs_write+0x68>
ffffffffc0203dfc:	0000d717          	auipc	a4,0xd
ffffffffc0203e00:	75473703          	ld	a4,1876(a4) # ffffffffc0211550 <max_swap_offset>
ffffffffc0203e04:	04e7fb63          	bgeu	a5,a4,ffffffffc0203e5a <swapfs_write+0x68>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203e08:	0000d617          	auipc	a2,0xd
ffffffffc0203e0c:	72063603          	ld	a2,1824(a2) # ffffffffc0211528 <pages>
ffffffffc0203e10:	8d91                	sub	a1,a1,a2
ffffffffc0203e12:	4035d613          	srai	a2,a1,0x3
ffffffffc0203e16:	00002597          	auipc	a1,0x2
ffffffffc0203e1a:	3aa5b583          	ld	a1,938(a1) # ffffffffc02061c0 <error_string+0x38>
ffffffffc0203e1e:	02b60633          	mul	a2,a2,a1
ffffffffc0203e22:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203e26:	00002797          	auipc	a5,0x2
ffffffffc0203e2a:	3a27b783          	ld	a5,930(a5) # ffffffffc02061c8 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e2e:	0000d717          	auipc	a4,0xd
ffffffffc0203e32:	6f273703          	ld	a4,1778(a4) # ffffffffc0211520 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203e36:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e38:	00c61793          	slli	a5,a2,0xc
ffffffffc0203e3c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203e3e:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e40:	02e7f963          	bgeu	a5,a4,ffffffffc0203e72 <swapfs_write+0x80>
}
ffffffffc0203e44:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e46:	0000d797          	auipc	a5,0xd
ffffffffc0203e4a:	6f27b783          	ld	a5,1778(a5) # ffffffffc0211538 <va_pa_offset>
ffffffffc0203e4e:	46a1                	li	a3,8
ffffffffc0203e50:	963e                	add	a2,a2,a5
ffffffffc0203e52:	4505                	li	a0,1
}
ffffffffc0203e54:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e56:	dacfc06f          	j	ffffffffc0200402 <ide_write_secs>
ffffffffc0203e5a:	86aa                	mv	a3,a0
ffffffffc0203e5c:	00002617          	auipc	a2,0x2
ffffffffc0203e60:	0fc60613          	addi	a2,a2,252 # ffffffffc0205f58 <default_pmm_manager+0x70>
ffffffffc0203e64:	45e5                	li	a1,25
ffffffffc0203e66:	00002517          	auipc	a0,0x2
ffffffffc0203e6a:	0da50513          	addi	a0,a0,218 # ffffffffc0205f40 <default_pmm_manager+0x58>
ffffffffc0203e6e:	a94fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203e72:	86b2                	mv	a3,a2
ffffffffc0203e74:	07100593          	li	a1,113
ffffffffc0203e78:	00001617          	auipc	a2,0x1
ffffffffc0203e7c:	f3860613          	addi	a2,a2,-200 # ffffffffc0204db0 <commands+0x760>
ffffffffc0203e80:	00001517          	auipc	a0,0x1
ffffffffc0203e84:	ef850513          	addi	a0,a0,-264 # ffffffffc0204d78 <commands+0x728>
ffffffffc0203e88:	a7afc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203e8c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203e8c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203e90:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203e92:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203e94:	cb81                	beqz	a5,ffffffffc0203ea4 <strlen+0x18>
        cnt ++;
ffffffffc0203e96:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203e98:	00a707b3          	add	a5,a4,a0
ffffffffc0203e9c:	0007c783          	lbu	a5,0(a5)
ffffffffc0203ea0:	fbfd                	bnez	a5,ffffffffc0203e96 <strlen+0xa>
ffffffffc0203ea2:	8082                	ret
    }
    return cnt;
}
ffffffffc0203ea4:	8082                	ret

ffffffffc0203ea6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203ea6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203ea8:	e589                	bnez	a1,ffffffffc0203eb2 <strnlen+0xc>
ffffffffc0203eaa:	a811                	j	ffffffffc0203ebe <strnlen+0x18>
        cnt ++;
ffffffffc0203eac:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203eae:	00f58863          	beq	a1,a5,ffffffffc0203ebe <strnlen+0x18>
ffffffffc0203eb2:	00f50733          	add	a4,a0,a5
ffffffffc0203eb6:	00074703          	lbu	a4,0(a4)
ffffffffc0203eba:	fb6d                	bnez	a4,ffffffffc0203eac <strnlen+0x6>
ffffffffc0203ebc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203ebe:	852e                	mv	a0,a1
ffffffffc0203ec0:	8082                	ret

ffffffffc0203ec2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203ec2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203ec4:	0005c703          	lbu	a4,0(a1)
ffffffffc0203ec8:	0785                	addi	a5,a5,1
ffffffffc0203eca:	0585                	addi	a1,a1,1
ffffffffc0203ecc:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203ed0:	fb75                	bnez	a4,ffffffffc0203ec4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203ed2:	8082                	ret

ffffffffc0203ed4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ed4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ed8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203edc:	cb89                	beqz	a5,ffffffffc0203eee <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203ede:	0505                	addi	a0,a0,1
ffffffffc0203ee0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ee2:	fee789e3          	beq	a5,a4,ffffffffc0203ed4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ee6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203eea:	9d19                	subw	a0,a0,a4
ffffffffc0203eec:	8082                	ret
ffffffffc0203eee:	4501                	li	a0,0
ffffffffc0203ef0:	bfed                	j	ffffffffc0203eea <strcmp+0x16>

ffffffffc0203ef2 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203ef2:	00054783          	lbu	a5,0(a0)
ffffffffc0203ef6:	c799                	beqz	a5,ffffffffc0203f04 <strchr+0x12>
        if (*s == c) {
ffffffffc0203ef8:	00f58763          	beq	a1,a5,ffffffffc0203f06 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203efc:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203f00:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203f02:	fbfd                	bnez	a5,ffffffffc0203ef8 <strchr+0x6>
    }
    return NULL;
ffffffffc0203f04:	4501                	li	a0,0
}
ffffffffc0203f06:	8082                	ret

ffffffffc0203f08 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203f08:	ca01                	beqz	a2,ffffffffc0203f18 <memset+0x10>
ffffffffc0203f0a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203f0c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203f0e:	0785                	addi	a5,a5,1
ffffffffc0203f10:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203f14:	fec79de3          	bne	a5,a2,ffffffffc0203f0e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203f18:	8082                	ret

ffffffffc0203f1a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203f1a:	ca19                	beqz	a2,ffffffffc0203f30 <memcpy+0x16>
ffffffffc0203f1c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203f1e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203f20:	0005c703          	lbu	a4,0(a1)
ffffffffc0203f24:	0585                	addi	a1,a1,1
ffffffffc0203f26:	0785                	addi	a5,a5,1
ffffffffc0203f28:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203f2c:	fec59ae3          	bne	a1,a2,ffffffffc0203f20 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203f30:	8082                	ret

ffffffffc0203f32 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203f32:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f36:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203f38:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f3c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203f3e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f42:	f022                	sd	s0,32(sp)
ffffffffc0203f44:	ec26                	sd	s1,24(sp)
ffffffffc0203f46:	e84a                	sd	s2,16(sp)
ffffffffc0203f48:	f406                	sd	ra,40(sp)
ffffffffc0203f4a:	e44e                	sd	s3,8(sp)
ffffffffc0203f4c:	84aa                	mv	s1,a0
ffffffffc0203f4e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203f50:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203f54:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203f56:	03067e63          	bgeu	a2,a6,ffffffffc0203f92 <printnum+0x60>
ffffffffc0203f5a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203f5c:	00805763          	blez	s0,ffffffffc0203f6a <printnum+0x38>
ffffffffc0203f60:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203f62:	85ca                	mv	a1,s2
ffffffffc0203f64:	854e                	mv	a0,s3
ffffffffc0203f66:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203f68:	fc65                	bnez	s0,ffffffffc0203f60 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f6a:	1a02                	slli	s4,s4,0x20
ffffffffc0203f6c:	00002797          	auipc	a5,0x2
ffffffffc0203f70:	00c78793          	addi	a5,a5,12 # ffffffffc0205f78 <default_pmm_manager+0x90>
ffffffffc0203f74:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203f78:	9a3e                	add	s4,s4,a5
}
ffffffffc0203f7a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f7c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203f80:	70a2                	ld	ra,40(sp)
ffffffffc0203f82:	69a2                	ld	s3,8(sp)
ffffffffc0203f84:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f86:	85ca                	mv	a1,s2
ffffffffc0203f88:	87a6                	mv	a5,s1
}
ffffffffc0203f8a:	6942                	ld	s2,16(sp)
ffffffffc0203f8c:	64e2                	ld	s1,24(sp)
ffffffffc0203f8e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f90:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203f92:	03065633          	divu	a2,a2,a6
ffffffffc0203f96:	8722                	mv	a4,s0
ffffffffc0203f98:	f9bff0ef          	jal	ra,ffffffffc0203f32 <printnum>
ffffffffc0203f9c:	b7f9                	j	ffffffffc0203f6a <printnum+0x38>

ffffffffc0203f9e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203f9e:	7119                	addi	sp,sp,-128
ffffffffc0203fa0:	f4a6                	sd	s1,104(sp)
ffffffffc0203fa2:	f0ca                	sd	s2,96(sp)
ffffffffc0203fa4:	ecce                	sd	s3,88(sp)
ffffffffc0203fa6:	e8d2                	sd	s4,80(sp)
ffffffffc0203fa8:	e4d6                	sd	s5,72(sp)
ffffffffc0203faa:	e0da                	sd	s6,64(sp)
ffffffffc0203fac:	fc5e                	sd	s7,56(sp)
ffffffffc0203fae:	f06a                	sd	s10,32(sp)
ffffffffc0203fb0:	fc86                	sd	ra,120(sp)
ffffffffc0203fb2:	f8a2                	sd	s0,112(sp)
ffffffffc0203fb4:	f862                	sd	s8,48(sp)
ffffffffc0203fb6:	f466                	sd	s9,40(sp)
ffffffffc0203fb8:	ec6e                	sd	s11,24(sp)
ffffffffc0203fba:	892a                	mv	s2,a0
ffffffffc0203fbc:	84ae                	mv	s1,a1
ffffffffc0203fbe:	8d32                	mv	s10,a2
ffffffffc0203fc0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fc2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203fc6:	5b7d                	li	s6,-1
ffffffffc0203fc8:	00002a97          	auipc	s5,0x2
ffffffffc0203fcc:	fe4a8a93          	addi	s5,s5,-28 # ffffffffc0205fac <default_pmm_manager+0xc4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203fd0:	00002b97          	auipc	s7,0x2
ffffffffc0203fd4:	1b8b8b93          	addi	s7,s7,440 # ffffffffc0206188 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fd8:	000d4503          	lbu	a0,0(s10) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0203fdc:	001d0413          	addi	s0,s10,1
ffffffffc0203fe0:	01350a63          	beq	a0,s3,ffffffffc0203ff4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203fe4:	c121                	beqz	a0,ffffffffc0204024 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203fe6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fe8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203fea:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fec:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203ff0:	ff351ae3          	bne	a0,s3,ffffffffc0203fe4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ff4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203ff8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203ffc:	4c81                	li	s9,0
ffffffffc0203ffe:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0204000:	5c7d                	li	s8,-1
ffffffffc0204002:	5dfd                	li	s11,-1
ffffffffc0204004:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0204008:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020400a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020400e:	0ff5f593          	zext.b	a1,a1
ffffffffc0204012:	00140d13          	addi	s10,s0,1
ffffffffc0204016:	04b56263          	bltu	a0,a1,ffffffffc020405a <vprintfmt+0xbc>
ffffffffc020401a:	058a                	slli	a1,a1,0x2
ffffffffc020401c:	95d6                	add	a1,a1,s5
ffffffffc020401e:	4194                	lw	a3,0(a1)
ffffffffc0204020:	96d6                	add	a3,a3,s5
ffffffffc0204022:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204024:	70e6                	ld	ra,120(sp)
ffffffffc0204026:	7446                	ld	s0,112(sp)
ffffffffc0204028:	74a6                	ld	s1,104(sp)
ffffffffc020402a:	7906                	ld	s2,96(sp)
ffffffffc020402c:	69e6                	ld	s3,88(sp)
ffffffffc020402e:	6a46                	ld	s4,80(sp)
ffffffffc0204030:	6aa6                	ld	s5,72(sp)
ffffffffc0204032:	6b06                	ld	s6,64(sp)
ffffffffc0204034:	7be2                	ld	s7,56(sp)
ffffffffc0204036:	7c42                	ld	s8,48(sp)
ffffffffc0204038:	7ca2                	ld	s9,40(sp)
ffffffffc020403a:	7d02                	ld	s10,32(sp)
ffffffffc020403c:	6de2                	ld	s11,24(sp)
ffffffffc020403e:	6109                	addi	sp,sp,128
ffffffffc0204040:	8082                	ret
            padc = '0';
ffffffffc0204042:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204044:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204048:	846a                	mv	s0,s10
ffffffffc020404a:	00140d13          	addi	s10,s0,1
ffffffffc020404e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204052:	0ff5f593          	zext.b	a1,a1
ffffffffc0204056:	fcb572e3          	bgeu	a0,a1,ffffffffc020401a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020405a:	85a6                	mv	a1,s1
ffffffffc020405c:	02500513          	li	a0,37
ffffffffc0204060:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204062:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204066:	8d22                	mv	s10,s0
ffffffffc0204068:	f73788e3          	beq	a5,s3,ffffffffc0203fd8 <vprintfmt+0x3a>
ffffffffc020406c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204070:	1d7d                	addi	s10,s10,-1
ffffffffc0204072:	ff379de3          	bne	a5,s3,ffffffffc020406c <vprintfmt+0xce>
ffffffffc0204076:	b78d                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204078:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020407c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204080:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204082:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204086:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020408a:	02d86463          	bltu	a6,a3,ffffffffc02040b2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020408e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204092:	002c169b          	slliw	a3,s8,0x2
ffffffffc0204096:	0186873b          	addw	a4,a3,s8
ffffffffc020409a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020409e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02040a0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02040a4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02040a6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02040aa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02040ae:	fed870e3          	bgeu	a6,a3,ffffffffc020408e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02040b2:	f40ddce3          	bgez	s11,ffffffffc020400a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02040b6:	8de2                	mv	s11,s8
ffffffffc02040b8:	5c7d                	li	s8,-1
ffffffffc02040ba:	bf81                	j	ffffffffc020400a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02040bc:	fffdc693          	not	a3,s11
ffffffffc02040c0:	96fd                	srai	a3,a3,0x3f
ffffffffc02040c2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040c6:	00144603          	lbu	a2,1(s0)
ffffffffc02040ca:	2d81                	sext.w	s11,s11
ffffffffc02040cc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02040ce:	bf35                	j	ffffffffc020400a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02040d0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040d4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02040d8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040da:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02040dc:	bfd9                	j	ffffffffc02040b2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02040de:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02040e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02040e4:	01174463          	blt	a4,a7,ffffffffc02040ec <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02040e8:	1a088e63          	beqz	a7,ffffffffc02042a4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02040ec:	000a3603          	ld	a2,0(s4)
ffffffffc02040f0:	46c1                	li	a3,16
ffffffffc02040f2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02040f4:	2781                	sext.w	a5,a5
ffffffffc02040f6:	876e                	mv	a4,s11
ffffffffc02040f8:	85a6                	mv	a1,s1
ffffffffc02040fa:	854a                	mv	a0,s2
ffffffffc02040fc:	e37ff0ef          	jal	ra,ffffffffc0203f32 <printnum>
            break;
ffffffffc0204100:	bde1                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0204102:	000a2503          	lw	a0,0(s4)
ffffffffc0204106:	85a6                	mv	a1,s1
ffffffffc0204108:	0a21                	addi	s4,s4,8
ffffffffc020410a:	9902                	jalr	s2
            break;
ffffffffc020410c:	b5f1                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020410e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204110:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204114:	01174463          	blt	a4,a7,ffffffffc020411c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0204118:	18088163          	beqz	a7,ffffffffc020429a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020411c:	000a3603          	ld	a2,0(s4)
ffffffffc0204120:	46a9                	li	a3,10
ffffffffc0204122:	8a2e                	mv	s4,a1
ffffffffc0204124:	bfc1                	j	ffffffffc02040f4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204126:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020412a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020412c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020412e:	bdf1                	j	ffffffffc020400a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204130:	85a6                	mv	a1,s1
ffffffffc0204132:	02500513          	li	a0,37
ffffffffc0204136:	9902                	jalr	s2
            break;
ffffffffc0204138:	b545                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020413a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020413e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204140:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204142:	b5e1                	j	ffffffffc020400a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204144:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204146:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020414a:	01174463          	blt	a4,a7,ffffffffc0204152 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020414e:	14088163          	beqz	a7,ffffffffc0204290 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204152:	000a3603          	ld	a2,0(s4)
ffffffffc0204156:	46a1                	li	a3,8
ffffffffc0204158:	8a2e                	mv	s4,a1
ffffffffc020415a:	bf69                	j	ffffffffc02040f4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020415c:	03000513          	li	a0,48
ffffffffc0204160:	85a6                	mv	a1,s1
ffffffffc0204162:	e03e                	sd	a5,0(sp)
ffffffffc0204164:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204166:	85a6                	mv	a1,s1
ffffffffc0204168:	07800513          	li	a0,120
ffffffffc020416c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020416e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204170:	6782                	ld	a5,0(sp)
ffffffffc0204172:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204174:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204178:	bfb5                	j	ffffffffc02040f4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020417a:	000a3403          	ld	s0,0(s4)
ffffffffc020417e:	008a0713          	addi	a4,s4,8
ffffffffc0204182:	e03a                	sd	a4,0(sp)
ffffffffc0204184:	14040263          	beqz	s0,ffffffffc02042c8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204188:	0fb05763          	blez	s11,ffffffffc0204276 <vprintfmt+0x2d8>
ffffffffc020418c:	02d00693          	li	a3,45
ffffffffc0204190:	0cd79163          	bne	a5,a3,ffffffffc0204252 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204194:	00044783          	lbu	a5,0(s0)
ffffffffc0204198:	0007851b          	sext.w	a0,a5
ffffffffc020419c:	cf85                	beqz	a5,ffffffffc02041d4 <vprintfmt+0x236>
ffffffffc020419e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02041a2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041a6:	000c4563          	bltz	s8,ffffffffc02041b0 <vprintfmt+0x212>
ffffffffc02041aa:	3c7d                	addiw	s8,s8,-1
ffffffffc02041ac:	036c0263          	beq	s8,s6,ffffffffc02041d0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02041b0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02041b2:	0e0c8e63          	beqz	s9,ffffffffc02042ae <vprintfmt+0x310>
ffffffffc02041b6:	3781                	addiw	a5,a5,-32
ffffffffc02041b8:	0ef47b63          	bgeu	s0,a5,ffffffffc02042ae <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02041bc:	03f00513          	li	a0,63
ffffffffc02041c0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041c2:	000a4783          	lbu	a5,0(s4)
ffffffffc02041c6:	3dfd                	addiw	s11,s11,-1
ffffffffc02041c8:	0a05                	addi	s4,s4,1
ffffffffc02041ca:	0007851b          	sext.w	a0,a5
ffffffffc02041ce:	ffe1                	bnez	a5,ffffffffc02041a6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02041d0:	01b05963          	blez	s11,ffffffffc02041e2 <vprintfmt+0x244>
ffffffffc02041d4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02041d6:	85a6                	mv	a1,s1
ffffffffc02041d8:	02000513          	li	a0,32
ffffffffc02041dc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02041de:	fe0d9be3          	bnez	s11,ffffffffc02041d4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02041e2:	6a02                	ld	s4,0(sp)
ffffffffc02041e4:	bbd5                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02041e6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02041e8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02041ec:	01174463          	blt	a4,a7,ffffffffc02041f4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02041f0:	08088d63          	beqz	a7,ffffffffc020428a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02041f4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02041f8:	0a044d63          	bltz	s0,ffffffffc02042b2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02041fc:	8622                	mv	a2,s0
ffffffffc02041fe:	8a66                	mv	s4,s9
ffffffffc0204200:	46a9                	li	a3,10
ffffffffc0204202:	bdcd                	j	ffffffffc02040f4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0204204:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204208:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020420a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020420c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204210:	8fb5                	xor	a5,a5,a3
ffffffffc0204212:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204216:	02d74163          	blt	a4,a3,ffffffffc0204238 <vprintfmt+0x29a>
ffffffffc020421a:	00369793          	slli	a5,a3,0x3
ffffffffc020421e:	97de                	add	a5,a5,s7
ffffffffc0204220:	639c                	ld	a5,0(a5)
ffffffffc0204222:	cb99                	beqz	a5,ffffffffc0204238 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204224:	86be                	mv	a3,a5
ffffffffc0204226:	00002617          	auipc	a2,0x2
ffffffffc020422a:	d8260613          	addi	a2,a2,-638 # ffffffffc0205fa8 <default_pmm_manager+0xc0>
ffffffffc020422e:	85a6                	mv	a1,s1
ffffffffc0204230:	854a                	mv	a0,s2
ffffffffc0204232:	0ce000ef          	jal	ra,ffffffffc0204300 <printfmt>
ffffffffc0204236:	b34d                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204238:	00002617          	auipc	a2,0x2
ffffffffc020423c:	d6060613          	addi	a2,a2,-672 # ffffffffc0205f98 <default_pmm_manager+0xb0>
ffffffffc0204240:	85a6                	mv	a1,s1
ffffffffc0204242:	854a                	mv	a0,s2
ffffffffc0204244:	0bc000ef          	jal	ra,ffffffffc0204300 <printfmt>
ffffffffc0204248:	bb41                	j	ffffffffc0203fd8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020424a:	00002417          	auipc	s0,0x2
ffffffffc020424e:	d4640413          	addi	s0,s0,-698 # ffffffffc0205f90 <default_pmm_manager+0xa8>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204252:	85e2                	mv	a1,s8
ffffffffc0204254:	8522                	mv	a0,s0
ffffffffc0204256:	e43e                	sd	a5,8(sp)
ffffffffc0204258:	c4fff0ef          	jal	ra,ffffffffc0203ea6 <strnlen>
ffffffffc020425c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204260:	01b05b63          	blez	s11,ffffffffc0204276 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0204264:	67a2                	ld	a5,8(sp)
ffffffffc0204266:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020426a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020426c:	85a6                	mv	a1,s1
ffffffffc020426e:	8552                	mv	a0,s4
ffffffffc0204270:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204272:	fe0d9ce3          	bnez	s11,ffffffffc020426a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204276:	00044783          	lbu	a5,0(s0)
ffffffffc020427a:	00140a13          	addi	s4,s0,1
ffffffffc020427e:	0007851b          	sext.w	a0,a5
ffffffffc0204282:	d3a5                	beqz	a5,ffffffffc02041e2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204284:	05e00413          	li	s0,94
ffffffffc0204288:	bf39                	j	ffffffffc02041a6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020428a:	000a2403          	lw	s0,0(s4)
ffffffffc020428e:	b7ad                	j	ffffffffc02041f8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204290:	000a6603          	lwu	a2,0(s4)
ffffffffc0204294:	46a1                	li	a3,8
ffffffffc0204296:	8a2e                	mv	s4,a1
ffffffffc0204298:	bdb1                	j	ffffffffc02040f4 <vprintfmt+0x156>
ffffffffc020429a:	000a6603          	lwu	a2,0(s4)
ffffffffc020429e:	46a9                	li	a3,10
ffffffffc02042a0:	8a2e                	mv	s4,a1
ffffffffc02042a2:	bd89                	j	ffffffffc02040f4 <vprintfmt+0x156>
ffffffffc02042a4:	000a6603          	lwu	a2,0(s4)
ffffffffc02042a8:	46c1                	li	a3,16
ffffffffc02042aa:	8a2e                	mv	s4,a1
ffffffffc02042ac:	b5a1                	j	ffffffffc02040f4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02042ae:	9902                	jalr	s2
ffffffffc02042b0:	bf09                	j	ffffffffc02041c2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02042b2:	85a6                	mv	a1,s1
ffffffffc02042b4:	02d00513          	li	a0,45
ffffffffc02042b8:	e03e                	sd	a5,0(sp)
ffffffffc02042ba:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02042bc:	6782                	ld	a5,0(sp)
ffffffffc02042be:	8a66                	mv	s4,s9
ffffffffc02042c0:	40800633          	neg	a2,s0
ffffffffc02042c4:	46a9                	li	a3,10
ffffffffc02042c6:	b53d                	j	ffffffffc02040f4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02042c8:	03b05163          	blez	s11,ffffffffc02042ea <vprintfmt+0x34c>
ffffffffc02042cc:	02d00693          	li	a3,45
ffffffffc02042d0:	f6d79de3          	bne	a5,a3,ffffffffc020424a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02042d4:	00002417          	auipc	s0,0x2
ffffffffc02042d8:	cbc40413          	addi	s0,s0,-836 # ffffffffc0205f90 <default_pmm_manager+0xa8>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02042dc:	02800793          	li	a5,40
ffffffffc02042e0:	02800513          	li	a0,40
ffffffffc02042e4:	00140a13          	addi	s4,s0,1
ffffffffc02042e8:	bd6d                	j	ffffffffc02041a2 <vprintfmt+0x204>
ffffffffc02042ea:	00002a17          	auipc	s4,0x2
ffffffffc02042ee:	ca7a0a13          	addi	s4,s4,-857 # ffffffffc0205f91 <default_pmm_manager+0xa9>
ffffffffc02042f2:	02800513          	li	a0,40
ffffffffc02042f6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02042fa:	05e00413          	li	s0,94
ffffffffc02042fe:	b565                	j	ffffffffc02041a6 <vprintfmt+0x208>

ffffffffc0204300 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204300:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204302:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204306:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204308:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020430a:	ec06                	sd	ra,24(sp)
ffffffffc020430c:	f83a                	sd	a4,48(sp)
ffffffffc020430e:	fc3e                	sd	a5,56(sp)
ffffffffc0204310:	e0c2                	sd	a6,64(sp)
ffffffffc0204312:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204314:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204316:	c89ff0ef          	jal	ra,ffffffffc0203f9e <vprintfmt>
}
ffffffffc020431a:	60e2                	ld	ra,24(sp)
ffffffffc020431c:	6161                	addi	sp,sp,80
ffffffffc020431e:	8082                	ret

ffffffffc0204320 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0204320:	715d                	addi	sp,sp,-80
ffffffffc0204322:	e486                	sd	ra,72(sp)
ffffffffc0204324:	e0a6                	sd	s1,64(sp)
ffffffffc0204326:	fc4a                	sd	s2,56(sp)
ffffffffc0204328:	f84e                	sd	s3,48(sp)
ffffffffc020432a:	f452                	sd	s4,40(sp)
ffffffffc020432c:	f056                	sd	s5,32(sp)
ffffffffc020432e:	ec5a                	sd	s6,24(sp)
ffffffffc0204330:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0204332:	c901                	beqz	a0,ffffffffc0204342 <readline+0x22>
ffffffffc0204334:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0204336:	00002517          	auipc	a0,0x2
ffffffffc020433a:	c7250513          	addi	a0,a0,-910 # ffffffffc0205fa8 <default_pmm_manager+0xc0>
ffffffffc020433e:	d7dfb0ef          	jal	ra,ffffffffc02000ba <cprintf>
readline(const char *prompt) {
ffffffffc0204342:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204344:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204346:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204348:	4aa9                	li	s5,10
ffffffffc020434a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020434c:	0000db97          	auipc	s7,0xd
ffffffffc0204350:	dacb8b93          	addi	s7,s7,-596 # ffffffffc02110f8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204354:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0204358:	d9bfb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc020435c:	00054a63          	bltz	a0,ffffffffc0204370 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204360:	00a95a63          	bge	s2,a0,ffffffffc0204374 <readline+0x54>
ffffffffc0204364:	029a5263          	bge	s4,s1,ffffffffc0204388 <readline+0x68>
        c = getchar();
ffffffffc0204368:	d8bfb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc020436c:	fe055ae3          	bgez	a0,ffffffffc0204360 <readline+0x40>
            return NULL;
ffffffffc0204370:	4501                	li	a0,0
ffffffffc0204372:	a091                	j	ffffffffc02043b6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0204374:	03351463          	bne	a0,s3,ffffffffc020439c <readline+0x7c>
ffffffffc0204378:	e8a9                	bnez	s1,ffffffffc02043ca <readline+0xaa>
        c = getchar();
ffffffffc020437a:	d79fb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc020437e:	fe0549e3          	bltz	a0,ffffffffc0204370 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204382:	fea959e3          	bge	s2,a0,ffffffffc0204374 <readline+0x54>
ffffffffc0204386:	4481                	li	s1,0
            cputchar(c);
ffffffffc0204388:	e42a                	sd	a0,8(sp)
ffffffffc020438a:	d67fb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i ++] = c;
ffffffffc020438e:	6522                	ld	a0,8(sp)
ffffffffc0204390:	009b87b3          	add	a5,s7,s1
ffffffffc0204394:	2485                	addiw	s1,s1,1
ffffffffc0204396:	00a78023          	sb	a0,0(a5)
ffffffffc020439a:	bf7d                	j	ffffffffc0204358 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020439c:	01550463          	beq	a0,s5,ffffffffc02043a4 <readline+0x84>
ffffffffc02043a0:	fb651ce3          	bne	a0,s6,ffffffffc0204358 <readline+0x38>
            cputchar(c);
ffffffffc02043a4:	d4dfb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i] = '\0';
ffffffffc02043a8:	0000d517          	auipc	a0,0xd
ffffffffc02043ac:	d5050513          	addi	a0,a0,-688 # ffffffffc02110f8 <buf>
ffffffffc02043b0:	94aa                	add	s1,s1,a0
ffffffffc02043b2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02043b6:	60a6                	ld	ra,72(sp)
ffffffffc02043b8:	6486                	ld	s1,64(sp)
ffffffffc02043ba:	7962                	ld	s2,56(sp)
ffffffffc02043bc:	79c2                	ld	s3,48(sp)
ffffffffc02043be:	7a22                	ld	s4,40(sp)
ffffffffc02043c0:	7a82                	ld	s5,32(sp)
ffffffffc02043c2:	6b62                	ld	s6,24(sp)
ffffffffc02043c4:	6bc2                	ld	s7,16(sp)
ffffffffc02043c6:	6161                	addi	sp,sp,80
ffffffffc02043c8:	8082                	ret
            cputchar(c);
ffffffffc02043ca:	4521                	li	a0,8
ffffffffc02043cc:	d25fb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            i --;
ffffffffc02043d0:	34fd                	addiw	s1,s1,-1
ffffffffc02043d2:	b759                	j	ffffffffc0204358 <readline+0x38>
