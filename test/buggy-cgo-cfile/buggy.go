package main

// #cgo LDFLAGS: -Wl,-z,relro
// #include <stdio.h>
// void myputs(char *input) {
//    char buf[1];
//    buf[1] = 0; // naughty
//    puts(buf);
//    puts(input);
// }
// void myputs2(char *);
// void foo();
import "C"

func main() {
	cs := C.CString("Hello, world!\n")
	C.myputs(cs)
	C.myputs2(cs)
	C.foo()
}
