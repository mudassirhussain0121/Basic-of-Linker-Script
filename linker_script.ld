
ENTRY(Reset_Handler)  /* Execution starts at Reset_Handler */


MEMORY {
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 256K  /* Flash is read-execute */
  RAM (xrw)  : ORIGIN = 0x20000000, LENGTH = 40K   /* RAM is read-write-execute */
}

SECTIONS {
	.isr_vector: {
		*(.isr_vector)
	} > FLASH
	
	.text: {
		*(.text*)
		*(.rodata*)
		. = ALIGN(4);
		PROVIDE(_etext = .);
	} > FLASH
	
	.data: {
		PROVIDE(_sdata = .);
		*(.data*)
		. = ALIGN(4);
		PROVIDE(_edata = .);
	} > RAM AT > FLASH
	
	.bss: {
		PROVIDE(_sbss = .);
		*(.bss*)
		*(COMMON)
		. = ALIGN(4);
		PROVIDE(_ebss = .);
	} > RAM
	
	/* --- Heap & Stack Sizes --- */
	_Min_Heap_Size  = 0x200;   /* 512 bytes heap */
	_Min_Stack_Size = 0x400;   /* 1 KB stack */
  
	._user_heap_stack: {
		. = ALIGN(8);
		PROVIDE(end = .);
		PROVIDE(_end = .); 
		. = . + _Min_Heap_Size;
		. = . + _Min_Stack_Size;
		. = ALIGN(8);
	} > RAM
	
	/* 6. Stack top (for startup code) */
	_estack = ORIGIN(RAM) + LENGTH(RAM);
}

