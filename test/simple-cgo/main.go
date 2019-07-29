package main

// #include <stdio.h>
import "C"

func main() {
	cs := C.CString("Hello, world!\n")
	cs.puts(cs)
}
