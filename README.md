# Basic-of-Linker-Script

## Linker

A linker is a program that takes one or more compiled object files (.o or .obj) and combines them into a single executable file (like .elf, .hex, .bin, or .exe).  

### What Does a Linker Do?

- <ins>Combines Code & Data:</ins>
	- Takes multiple .o files (from different .c files) and merges them.
	- Example: If main.c calls a function from math.c, the linker connects them.

- <ins>Resolves References:</ins>
	- If main.o uses a function from math.o, the linker finds and links them.
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
main.o doesn’t know where add() function is.


With linking:
gcc main.o math.o -o program  # The linker combines them!

Now, program knows how to call add() function from math.o.
```

![Linking Process](/readme_images/linking_process.png)

