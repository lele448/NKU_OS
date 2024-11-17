# lab3

## 练习1：理解基于FIFO的页面替换算法（思考题）

描述FIFO页面置换算法下，一个页面从**被换入到被换出**的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述**每个函数**在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）

- 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出**对执行过程有实际影响,删去后会导致输出结果不同的函数**（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数



- 根据阅读实验指导手册，我们知道缺页异常指的是当CPU访问的虚拟地址时， MMU没有办法找到对应的物理地址映射关系，或者与该物理页的访问权不一致而发生的异常。遇到缺页异常时，异常处理程序会把Page Fault分发给`kern/mm/vmm.c`的`do_pgfault()`函数并尝试进行页面置换。

在`do_pgfault()`函数中，如果交换机制已经初始化了（`swap_init_ok` 为真），则会调用swap_in()、page_insert()、swap_map_swappable()函数。

```c
int swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)
{
     struct Page *result = alloc_page();//这里alloc_page()内部可能调用swap_out()
     //找到对应的一个物理页面
     assert(result!=NULL);

     pte_t *ptep = get_pte(mm->pgdir, addr, 0);//找到/构建对应的页表项
    //将物理地址映射到虚拟地址是在swap_in()退出之后，调用page_insert()完成的
     int r;
     if ((r = swapfs_read((*ptep), result)) != 0)//将数据从硬盘读到内存
     {
        assert(r!=0);
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
     *ptr_result=result;
     return 0;
}
```

swap_in()函数将在磁盘上的页面加载到内存中去。

在该函数里先会调用**`alloc_page()`**尝试分配一个新的物理页面，用于存放从磁盘交换区加载的数据。`alloc_page()` 返回一个指向 `Page` 结构体的指针，`Page` 结构体表示内存中的一个物理页面。

然后通过 `get_pte()`获取虚拟地址对应的页表项，该页表项指示该虚拟地址对应的物理地址。换入操作中需要根据该页表项来确定数据来源。

**`swapfs_read()`**：将数据从磁盘读取到内存中的物理页面 ，实现换入过程。如果 `swapfs_read()` 返回非零值，表示读取失败。



```c
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    //pgdir是页表基址(satp)，page对应物理页面，la是虚拟地址
    pte_t *ptep = get_pte(pgdir, la, 1);
    //先找到对应页表项的位置，如果原先不存在，get_pte()会分配页表项的内存
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    page_ref_inc(page);//指向这个物理页面的虚拟地址增加了一个
    if (*ptep & PTE_V) { //原先存在映射
        struct Page *p = pte2page(*ptep);
        if (p == page) {//如果这个映射原先就有
            page_ref_dec(page);
        } else {//如果原先这个虚拟地址映射到其他物理页面，那么需要删除映射
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);//构造页表项
    tlb_invalidate(pgdir, la);//页表改变之后要刷新TLB
    return 0;
}
```

`page_insert()`主要用于将虚拟地址 `la` 映射到物理页面 `page`，并更新页表。

在该函数中也是先利用`get_pte()`函数获取页表项pte。

`page_ref_inc()`函数会增加物理页面的引用计数。

然后在检查是否已有映射时，如果发现这个映射原先就有了，说明这是一个重复的映射，就会调用`page_ref_dec()`函数，减少物理页面的引用计数；如果原先这个虚拟地址映射到其他物理页面，那么需要删除映射，调用调用 `page_remove_pte()` 移除原有的映射。



```c
int swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);
}
```

swap_map_swappable()函数用于标记该页面可以被交换出去（可以在将来被换出到磁盘）。



- 根据FIFO算法，我们知道换入时，将所有页面排在一个队列中，每次换入就把队列中靠前（最早被换入）的页面置换出去。换出的时机主要是当发现没有空闲的物理页可以分配时，就开始查找”不常用“的页面，并把一个或多个这样的页面换出到磁盘上。

如果，目前系统试图得到空闲页且没有空闲的物理页时，便会尝试换出页面到硬盘上：在`alloc_pages` 函数尝试分配 n个物理页面，如果当前内存中没有足够的页面可用，便会调用页面置换机制（swap）来释放一些页面，从而腾出空间进行分配：

```c
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);
        //如果有足够的物理页面，就不必换出其他页面
        //如果n>1, 说明希望分配多个连续的页面，但是我们换出页面的时候并不能换出连续的页面
         //swap_init_ok标志是否成功初始化了
        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        swap_out(check_mm_struct, n, 0);//调用页面置换的”换出页面“接口。这里必有n=1
    }
    return page;
}
```

从上面代码可以看到当没有足够页可以用时，会调用swap_out函数，将物理页面从内存写回到磁盘的交换区，从而释放物理内存：

```c
int swap_out(struct mm_struct *mm, int n, int in_tick)
{
     int i;
     for (i = 0; i != n; ++ i)
     {
          uintptr_t v;
          struct Page *page;
          int r = sm->swap_out_victim(mm, &page, in_tick);//调用页面置换算法的接口
          //r=0表示成功找到了可以换出去的页面
         //要换出去的物理页面存在page里
          if (r != 0) {
                  cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
                  break;
          }

          cprintf("SWAP: choose victim page 0x%08x\n", page);

          v=page->pra_vaddr;//可以获取物理页面对应的虚拟地址
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
          assert((*ptep & PTE_V) != 0);

          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
                      //尝试把要换出的物理页面写到硬盘上的交换区，返回值不为0说明失败了
                    cprintf("SWAP: failed to save\n");
                    sm->map_swappable(mm, v, page, 0);
                    continue;
          }
          else {
              //成功换出
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
                    free_page(page);
          }
          //由于页表改变了，需要刷新TLB
          //思考： swap_in()的时候插入新的页表项之后在哪里刷新了TLB?
          tlb_invalidate(mm->pgdir, v);
     }
     return i;
}
```

在该函数中，首先遇到`swap_out_victim()`，它时页面置换算法的接口，返回一个可以被换出的页面page，如果返回值r为0，则表示找到了一个可以被换出的页面；如果返回为非0，表示没有找到可以被换出的页面1。在`swap_manager_fifo` 结构体中，设置 `swap_out_victim` 函数指针为 `&_fifo_swap_out_victim`。`_fifo_swap_out_victim` 是在 FIFO 页面替换算法中实现的一个函数，该函数会负责选择一个页面进行换出，该页面就是最早到达的页面，在该函数内这个页面会被移除并标记为要换出的页面，返回该页面的指针。

`swapfs_write()`函数尝试将页面写回到磁盘，如果函数返回值不为0则表示写入失败。

`free_page()`则会释放被换出的页面。

`tlb_invalidate()`会进行TLB的树新，因为由于页表项发生了变化，需要刷新TLB缓存，确保下次访问时使用最新的映射。





## 练习2：深入理解不同分页模式的工作原理（思考题）

get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

- get_pte()函数中有两段形式类似的代码， **结合sv32，sv39，sv48的异同**，解释这两段代码为什么如此相像。

```c
//寻找(有必要的时候分配)一个页表项
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    /* LAB2 EXERCISE 2: YOUR CODE
     *
     * If you need to visit a physical address, please use KADDR()
     * please read pmm.h for useful macros
     *
     * Maybe you want help comment, BELOW comments can help you finish the code
     *
     * Some Useful MACROs and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   PDX(la) = the index of page directory entry of VIRTUAL ADDRESS la.
     *   KADDR(pa) : takes a physical address and returns the corresponding
     * kernel virtual address.
     *   set_page_ref(page,1) : means the page be referenced by one time
     *   page2pa(page): get the physical address of memory which this (struct
     * Page *) page  manages
     *   struct Page * alloc_page() : allocation a page
     *   memset(void *s, char c, size_t n) : sets the first n bytes of the
     * memory area pointed by s
     *                                       to the specified value c.
     * DEFINEs:
     *   PTE_P           0x001                   // page table/directory entry
     * flags bit : Present
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];//找到对应的Giga Page
    if (!(*pdep1 & PTE_V)) {//如果下一级页表不存在，那就给它分配一页，创造新页表
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        //我们现在在虚拟地址空间中，所以要转化为KADDR再memset.
        //不管页表怎么构造，我们确保物理地址和虚拟地址的偏移量始终相同，那么就可以用这种方式完成对物理内存的访问。
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);//注意这里R,W,X全零
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];//再下一级页表
    //这里的逻辑和前面完全一致，页表不存在就现在分配一个
    if (!(*pdep0 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
                return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    //找到输入的虚拟地址la对应的页表项的地址(可能是刚刚分配的)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}
```

`get_pte` 函数用于根据给定的虚拟地址 `la` 查找或创建页表项，并返回该页表项的地址。

我们知道三级页表从高到低表示为：PDX1、PDX0、PTX。所以函数中的第一部分是找**大大页（即一级页表项）**，如果页表项不存在，需要利用函数**`alloc_page()`**分配一个新的物理页面用于存储页表。并且还需要**`set_page_ref(page, 1)`**设置该物理页面的引用计数为 1，因为现在它用于存储页表，所以需要增加引用计数，确保页面在系统中是有效的。然后将分配得到的物理页面page转化为物理地址，利用`KADDR`宏定义将物理地址转化为内核虚拟地址，并且初始化分配的物理页面，将该页面的所有字节设置为 0。最后需要创建一个新的页表项，映射到刚刚分配的物理页面。

如果找到了大大页（即一级页表项），使用 `PDE_ADDR(*pdep1)` 提取该页目录项的物理地址，并将其转换为页表的虚拟地址。然后使用 `PDX0(la)` 来计算第二层页表项的索引，即开始寻找第二级页表项。与第一级页表项类过程类似。

在SV32、SV39、SV48中，SV后面两位数字表示虚拟地址位数。

**SV32：**32位虚拟地址，是两级页表，有1024个大页，每个大页又包含1024个页，每个页里有4096个字节。

**SV39：**39位虚拟地址，三级页表，有512个大大页，大大页中有512个大页，大页中又有512个页，每个页里有4096个字节。

**SV48:**48位虚拟地址，四级页表，有512个大大大页，大大大页中有512个大大页，大大页中又有512个大页，每个大页又包含1024个页，每个页里有4096个字节。

所以通过页表项的层次结构，看出为何以上代码有两部分十分相似，是因为在多级页表中，操作基本是一样的，都是从最高级的页表查找到最低级别的页，如果出现页表项不存在的情况，就会进行重新分配。



- 目前get_pte()函数将页表项的**查找**和页表项的**分配**合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

我觉得没有必要拆开，如果拆开可能导致资源的浪费和错误的页面分配。而且我认为页表项的**查找**和页表项的**分配**是较为密切的操作，所以合并在一起更好。

合并在一起的优点：

1. 确保了逻辑一致性：由于这两个操作在一个函数中，可以确保操作的一致性，且使得代码更加容易理解也更加容易维护。
2. 性能开销减少：将页表项的查找和页表项的分配操作写在一个函数中，减少了函数调用的开销，而且如果遇到大量涉及页表项的查找和页表项的分配操作时，性能优化效果更明显。
3. 减少冗余：如果分成两个函数，则页表项的查找和页表项的分配函数可能会含有一些相似的结构，合并在一起可以更好地减少代码冗余。



## 练习三

- **设计实现过程**：

  + `swap_in(mm,addr,&page)`：首先需要根据页表基地址和虚拟地址完成磁盘的读取，写入内存，返回内存中的物理页。

  + `page_insert(mm->pgdir,page,addr,perm)`：然后完成虚拟地址和内存中物理页的映射。
  + `swap_map_swappable(mm,addr,page,0)`：最后设置该页面是可交换的。

+ **潜在用处**：页目录项和页表项中的合法位可以用来判断该页面是否存在，还有一些其他的权限位，比如可读可写，可以用于CLOCK算法或LRU算法。修改位可以决定在换出页面时是否需要写回磁盘。
+ **页访问异常**：trap--> trap_dispatch-->pgfault_handler-->do_pgfault
  + 首先保存当前异常原因，根据`stvec`的地址跳转到中断处理程序，即`trap.c`文件中的`trap`函数。
  + 接着跳转到`exception_handler`中的`CAUSE_LOAD_ACCESS`处理缺页异常。
  + 然后跳转到`pgfault_handler`，再到`do_pgfault`具体处理缺页异常。
  + 如果处理成功，则返回到发生异常处继续执行。
  + 否则输出`unhandled page fault`。
+ **对应关系**：有对应关系。如果页表项映射到了物理地址，那么这个地址对应的就是`Page`中的一项。`Page` 结构体数组的每一项代表一个物理页面，并且可以通过页表项间接关联。页表项存储物理地址信息，这可以用来索引到对应的 `Page` 结构体，从而允许操作系统管理和跟踪物理内存的使用。





## 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）

如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

好处：

- 减少了页表的大小，在三级页表中一个页的大小为4KB，一个大页的大小为2MB。如果只采用一个大页，那么说明每个页面要对应更大的物理内存区域，所以页表项数量会减少。
- 访问速度会变快，由于只有一个大页，减少了页表层数，查找时就不用一级一级地查找下来，从而加快了内存访问速度。
- TLB缺少率减少，由于一个页面要对应更大的物理内存区域，页表项的数量降低，，则TLB中一个条目映射到了更多的内存范围，则TLB命中率变高。
- 更加简洁，管理开销减少。因为每个大页可以映射的内存空间更大，所需的页表项数量就少，因此操作系统需要管理的页表数据结构就会较小，减少了内存中页表的管理开销。

坏处：

- 空间浪费，由于一个页面的大小变大，会导致很多虚拟地址都没有用到，会有大片大片的页表项的标志位为0（不合法），导致浪费内存空间。例如分配2MB大小的页但只用了5KB。
- 兼容性差，有些操作系统可能不支持大页。
- 实现更复杂，操作系统会寻求其他措施来提高page的利用率。



## 扩展练习

### 设计思路

将新加入的页面或刚刚访问的页插入到链表头部，这样每次换出页面时只需要将链表尾部的页面取出即可。

为了知道访问了哪个页面，可以在建立页表项时将每个页面的权限全部设置为不可读，这样在访问一个页面的时候会引发缺页异常，将所有页的页表项的权限设置为不可读，之后将该页放到链表头部，设置页面为可读。

### 代码实现

在`do_pgfault`中添加如下代码：

```c
pte_t* temp = NULL;
temp = get_pte(mm->pgdir, addr, 0);
if(temp != NULL && (*temp & (PTE_V | PTE_R))) {
    return lru_pgfault(mm, error_code, addr);
}
```

在为`perm`设置完权限之后，移除读权限：

```c
perm &= ~PTE_R;
```

`lru`的异常处理部分：

```c
int lru_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    cprintf("lru page fault at 0x%x\n", addr);
    // 设置所有页面不可读
    if(swap_init_ok) 
        unable_page_read(mm);
    // 将需要获得的页面设置为可读
    pte_t* ptep = NULL;
    ptep = get_pte(mm->pgdir, addr, 0);
    *ptep |= PTE_R;
    if(!swap_init_ok) 
        return 0;
    struct Page* page = pte2page(*ptep);
    // 将该页放在链表头部
    list_entry_t *head=(list_entry_t*) mm->sm_priv, *le = head;
    while ((le = list_prev(le)) != head)
    {
        struct Page* curr = le2page(le, pra_page_link);
        if(page == curr) {
            
            list_del(le);
            list_add(head, le);
            break;
        }
    }
    return 0;
}
```

设置所有页面不可读，原理是遍历链表，转换为`page`，根据`pra_vaddr`获得页表项，设置不可读：

```c
static int
unable_page_read(struct mm_struct *mm) {
    list_entry_t *head=(list_entry_t*) mm->sm_priv, *le = head;
    while ((le = list_prev(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        pte_t* ptep = NULL;
        ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        *ptep &= ~PTE_R;
    }
    return 0;
}
```

其余部分与`FIFO`算法差异不大，罗列如下：

```c
static int
_lru_init_mm(struct mm_struct *mm)
{     

    list_init(&pra_list_head);
    mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    list_add((list_entry_t*) mm->sm_priv,entry);
    return 0;
}
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}
```

### 测试

设计额外的测试如下：

```c
static void
print_mm_list() {
    cprintf("--------begin----------\n");
    list_entry_t *head = &pra_list_head, *le = head;
    while ((le = list_next(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        cprintf("vaddr: %x\n", page->pra_vaddr);
    }
    cprintf("---------end-----------\n");
}
static int
_lru_check_swap(void) {
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    return 0;
}
```

与测试有关的测试结果如下：

```c
set up init env for check_swap over!
--------begin----------
vaddr: 0x4000
vaddr: 0x3000
vaddr: 0x2000
vaddr: 0x1000
---------end-----------
write Virt Page c in lru_check_swap
Store/AMO page fault
page fault at 0x00003000: K/W
lru page fault at 0x3000
--------begin----------
vaddr: 0x3000
vaddr: 0x4000
vaddr: 0x2000
vaddr: 0x1000
---------end-----------
write Virt Page a in lru_check_swap
Store/AMO page fault
page fault at 0x00001000: K/W
lru page fault at 0x1000
--------begin----------
vaddr: 0x1000
vaddr: 0x3000
vaddr: 0x4000
vaddr: 0x2000
---------end-----------
write Virt Page b in lru_check_swap
Store/AMO page fault
page fault at 0x00002000: K/W
lru page fault at 0x2000
--------begin----------
vaddr: 0x2000
vaddr: 0x1000
vaddr: 0x3000
vaddr: 0x4000
---------end-----------

```

可以看到每次访问页面时都会产生缺页异常，将该页面添加到链表头部，需要移除页面时都从链表尾部删除页面。
