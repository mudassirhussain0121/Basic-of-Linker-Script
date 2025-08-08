# Basic-of-Linker-Script

## Linker

A linker is a program that takes one or more compiled object files (.o or .obj) and combines them into a single executable file (like .elf, .hex, .bin, or .exe).  

### What Does a Linker Do?

- <ins>Combines Code & Data:</ins>
	- Takes multiple `.o` files (from different .c files) and merges them.
	- Example: If `main.c` calls a function from `math.c`, the linker connects them.

- <ins>Resolves References:</ins>
	- If `main.o` uses a function from `math.o`, the linker finds and links them.
	- If something is missing (like an undefined function), it gives a "linker error".

- <ins>Decides Where Everything Goes in Memory:</ins>
	- Code (.text)            → Usually in Flash/ROM
	- Variables (.data, .bss) → Usually in RAM
	- Constants (.rodata)     → Usually in Flash/ROM

- <ins>Handles Libraries (lib.a, .so, .dll):</ins>
	- Links pre-compiled libraries (like printf from the C standard library).

```
// math.c
int add(int a, int b) { return a + b; }
 --------------

// main.c
int add(int a, int b); // Declaration
int main() { return add(2, 3); }
 --------------
 
gcc -c math.c → Produces math.o
gcc -c main.c → Produces main.o

Without linking:
`main.o` doesn’t know where `add()` function is.


With linking:
gcc main.o math.o -o program  # The linker combines them!

Now, program knows how to call `add()` function from `math.o`.
```


![Linking Process](/readme_images/linking_process.png)


### Why and When Linker needed a Linker Script (.ld File)?
A linker script (.ld file) is a configuration file that tells the linker:  
- Where to place code/data (Flash or RAM, etc.)
- How to organize memory (stack, heap, special sections (bootloader etc))
- How to resolve symbols (variables, functions, etc.)

## Linker Script (.ld File)

The main purpose of the linker script is to describe how the sections in the input files should be mapped into the output file and to control the memory layout of the output file.  
  
In other words, it controls how object files are combined into an executable or library by specifying memory layout, section placement, and symbol definitions.

- Purpose of .ld Files
	- Define memory regions (RAM, ROM, Flash).
	- Organize code and data sections (.text, .data, .bss, etc.).
	- Set entry points for programs (e.g., _start in embedded systems).
	- Handle special requirements (e.g., bootloaders, firmware).

### Basic Structure of a Linker Script

A typical linker script has these main parts:  
- `ENTRY()`  → Defines the program’s starting point.
- `MEMORY`   → Describes available memory regions.
- `SECTIONS` → Controls where code/data goes.
- `Symbol Definitions` → Variables used in startup code.


#### (1.) ENTRY() - Program Entry Point

This tells the linker where execution starts (usually `Reset_Handler` in embedded systems).

<ins>Syntax:</ins>

```
ENTRY(Reset_Handler)  /* Execution starts at Reset_Handler */
````

#### (2.) MEMORY - Defining Memory Regions

This describes physical memory (Flash, RAM) available in your chip.

<ins>Syntax:</ins>

```
MEMORY {
  NAME (ATTRIBUTES) : ORIGIN = START_ADDRESS, LENGTH = SIZE
}
```

<ins>Key Components:</ins>

`NAME` → A label (e.g., FLASH, RAM).  
`ATTRIBUTES` → Access permissions: 
``` 
 r = Readable  
 w = Writable  
 x = Executable  
 a = Allocatable  
```
`ORIGIN` → Start address (0x08000000 for STM32 Flash).  
`LENGTH` → Size (256K for STM32F4).

```
Example (STM32F303):

MEMORY {
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 256K  /* Flash is read-execute */
  RAM (xrw)  : ORIGIN = 0x20000000, LENGTH = 40K   /* RAM is read-write-execute */
}
```

#### (3.) SECTIONS - Placing Code & Data

This is where you control where .text, .data, .bss, etc., go.

<ins>Key Sections in Embedded Systems:</ins> 

| Section |	Contents                         | Usually Placed In |
|---------|----------------------------------|-------------------|
| .text	  | Code (functions, ISRs)	         | Flash (rx)  |
| .rodata | Read-only data (const variables) | Flash (rx)  |
| .data	  | Initialized variables	         | RAM (xrw)   |
| .bss	  | Uninitialized variables (zeroed) | RAM (xrw)   |
| .stack  | Stack memory                     | End of RAM  |
| .heap	  | Dynamic memory (malloc/free)     | After .bss  |

<ins>Syntax:</ins>

```
SECTIONS {
  .section_name : {
    *(.subsection)  /* Wildcard to match all `.subsection` in input files */
    . = ALIGN(4);   /* Align to 4 bytes (ARM requirement) */
    symbol = .;     /* Define a symbol at current location */
  } > MEMORY_REGION
}
````

<ins>Key Components:</ins>
- `.section_name`  → Name of the output section (e.g., .text, .data).
- `*(.subsection)` → Collects all input sections matching .subsection.
- `. = ALIGN(4);`  → Ensures the section is 4-byte aligned (critical for ARM).
- `symbol = .;`    → Defines a symbol (variable) at the current memory location.
- `> MEMORY_REGION` → Places this section in a memory region (defined in MEMORY).

##### (3.1) .section_name : { ... }
This defines an output section in the final executable.

````
Example sections:

  .text   → Code (functions, ISRs).
  .rodata → Read-only data.
  .data   → Initialized variables.
  .bss    → Zero-initialized variables.
````

> **❗ Important**: Sections (.text, .rodata, .data, and .bss) are created by the compiler (GCC/Clang) during compilation of your C/C++ code.

```
Example:

.text : {  /* All code will go into this section */
  *(.text*)
} > FLASH
```

##### (3.2) *(.subsection)
The `*(.subsection)` syntax is a wildcard that collects all input sections named `.subsection` from all object files (.o files).

```
Example:

*(.text*) → Matches .text, .text.startup, etc.
*(.rodata*) → Matches all read-only data.
```

##### (3.3) . = ALIGN(4);
The dot (.) represents the current memory address.
ALIGN(4) ensures the next section starts at a 4-byte boundary (required for ARM Cortex-M).
If the current address is 0x20000003, ALIGN(4) skips to 0x20000004.

```
Example:

.bss : {
  _sbss = .;     /* Current address (e.g., 0x20000000) */
  *(.bss*)       /* All .bss sections */
  . = ALIGN(4);  /* Skip to next 4-byte boundary */
  _ebss = .;     /* Now at 0x20000004 (if unaligned before) */
} > RAM
```

##### (3.4) symbol = .;
Defines a symbol (like a user variable) at the current location.
These symbols can be used in startup code (.s file) to know where section starts or ends.

```
Example symbols:

_stext → Start of .text section.
_etext → End of .text section.

_sbss → Start of .bss section.
_ebss → End of .bss section.

_estack → Top of the stack.
```

```
Example (used in startup code):

extern uint32_t _sbss, _ebss;
memset(&_sbss, 0, (&_ebss - &_sbss));  /* Zero out .bss */
```

##### (3.5) > MEMORY_REGION
Specifies where this section should be placed (defined in MEMORY).

```
Example regions:

> FLASH → Code goes into Flash.
> RAM → Variables go into RAM.
```

```
Example:

/* .text goes into FLASH region. */

.text : {
  *(.text*)      /* All `.text` sections from input files */
  *(.rodata*)    /* All `.rodata` sections */
  . = ALIGN(4);  /* Align to 4 bytes */
  _etext = .;    /* Symbol marking end of `.text` */
} > FLASH
```

Special Case: `.data` Section (Where data load from FALSH to RAM at runtime)

```
.data : {
  _sdata = .;
  *(.data*)
  _edata = .;
} > RAM AT > FLASH  /* Runs in RAM, but stored in Flash */

> RAM → Where `.data` executes (variables must be in RAM).
AT > FLASH → Where `.data` is stored (Flash retains initial values).

** Startup code must copy `.data` from Flash to RAM! **
```

```
Example:


/* --- Heap & Stack Sizes --- */
_Min_Heap_Size  = 0x200;   /* 512 bytes heap */
_Min_Stack_Size = 0x400;   /* 1 KB stack */


SECTIONS {
  /* 1. Interrupt Vector Table (must be at start of Flash) */
  .isr_vector : {
    *(.isr_vector)  /* Matches the vector table in startup file */
	KEEP(*(.isr_vector)) /* `KEEP` make sure it is not removed during optimization */
  } > FLASH

  /* 2. Code (.text) and read-only data (.rodata) */
  .text : {
                   /* Defining `_stext` is redundant because: `.text` section is the first section after vector table.
                      So, it's start address is know and no need to define expectily.
                   */
				   
    *(.text*)      /* All `.text` sections from input files.
                     (*) (before parentheses) Matches all input files (e.g., main.o, driver.o).
                     (.text*) Matches all sections whose names start with `.text`
                   */
    *(.rodata*)    /* All `.rodata` sections */
    . = ALIGN(4);  /* Align to 4 bytes */
    _etext = .;    /* Symbol marking end of `.text` */
  } > FLASH

  /* 3. `.data` section (initialized variables) */
  .data : {
    _sdata = .;       /* Start of `.data` in RAM */
    *(.data*)         /* All `.data` sections */
    . = ALIGN(4);
    _edata = .;       /* End of `.data` in RAM */
  } > RAM AT > FLASH  /* Loaded in Flash but runs in RAM */

  /* 4. `.bss` section (zero-initialized variables) */
  .bss : {
    _sbss = .;     /* Start of `.bss` */
    *(.bss*)       /* All `.bss` sections */
    *(COMMON)      /* Uninitialized globals */
    . = ALIGN(4);
    _ebss = .;     /* End of `.bss` */
  } > RAM


  /* 5. Stack & Heap */
  ._user_heap_stack : {                                 // The two ALIGN(8) serve different purposes in memory section placement:
    . = ALIGN(8); /* Ensures the starting address       // 1st ALIGN(8) (Before allocations):
                     is 8-byte aligned.                 //  - Ensures the heap/stack region starts on an 8-byte aligned address.
                  */                                    //  - `end/_end` symbols (used by _sbrk() for malloc) must be aligned.
    /* `end` and `_end`, Symbols marking the start      //  - ARM architectures often require 8-byte alignment for stack pointers.
      of the heap. Used by `_sbrk()` (in syscalls.c)    //  - Prevents misaligned access penalties (especially for double-word operations).
	   to manage `malloc()/free()`.                     // 2nd ALIGN(8) (After allocations):
    */                                                  //  - Pads the total RAM usage to an 8-byte boundary.
    PROVIDE(end = .);                                   //  - Ensures next memory section (if any) starts aligned.
    PROVIDE(_end = .);                                  //  - No wasted "slop space" between sections.
    . = . + _Min_Heap_Size;  /* Reserve heap space */   //  - Compliance with alignment requirements of subsequent data/code.
    . = . + _Min_Stack_Size; /* Reserve stack space */  
    . = ALIGN(8); /* Pads the total size to 8-byte boundary.
                     OR Maintains alignment for potential following sections. */
  } > RAM
  

  /* 6. Stack top (for startup code) */
  _estack = ORIGIN(RAM) + LENGTH(RAM);
}
```


<ins>Visualization (RAM Layout):</ins>

```
0x2000A000 +-------------------+
           | Stack (1KB)       |  <-- Grows downward
           |-------------------|
           | Heap (512B)       |  <-- `end and _end` (used by _sbrk for malloc)
           |-------------------|
           | .bss (zero-init)  |
           |-------------------|
           | .data             |
0x20000000 +-------------------+
```

#### (4.)Special Symbols & Commands

##### (4.1) . (Dot) - Memory Location Counter
Represents the current memory address. It like a cursor that keeps track of the current position in memory. 
When a section is added in the memory region then the cursor move forward and (.) keeps track of it.
 
```
Can be moved forward to reserve space:

. = . + 0x100;  /* Skip 256 bytes */
```

The (.) is implicitly used to track where these sections start and end.

```
_stext = .; /* Save current position into `_stext` (start of `.text` section)*/
_etext = .; /* Save current position into `_etext` (end of `.text` section)*/

_sbss = .;
_ebss = .;
```

```	
Example:

.isr_vector : {
  *(.isr_vector)  /* Place IVT here */
} > FLASH

.text : {
  *(.text*)       /* Place code here */
} > FLASH


Starts `.isr_vector` at 0x08000000 (Flash start).
After placing `.isr_vector`, (.) points to the next free address (e.g., 0x080000C0).
Then places `.text` at the new (.) position.
```   

##### (4.2) ALIGN(n) - Alignment
Ensures the next section starts at an n-byte boundary (ARM requires 4-byte alignment).

```
. = ALIGN(4);
```

##### (4.3) PROVIDE(symbol = value)
Defines a symbol only if not already defined (useful for heap/stack).

```
PROVIDE(end = .);  /* Used by `_sbrk()` (in syscalls.c) to manage `malloc()/free()` */
PROVIDE(_end = .); 
```

##### (4.4) KEEP() - Prevent Discarding
Keeps a section even if unused (critical for vector tables).  
`KEEP` makes sure that section is not removed during optimization.

```
KEEP(*(.isr_vector))
```
