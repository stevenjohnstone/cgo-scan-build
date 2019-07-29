package buggy

// #cgo LDFLAGS: -Wl,-z,relro
// #include <stdio.h>
// void myputs(char *input) {
//    char buf[1];
//    buf[1] = 0; // naughty
//    puts(buf);
//    puts(input);
// }
import "C"

func buggy() {
	cs := C.CString("Hello, world!\n")
	C.myputs(cs)
}
