# scan-build for cgo

[Golang](https://golang.org/) can be extended by and integrated with C code using [cgo](https://golang.org/cmd/cgo/). Unfortunately,
this [removes memory safety](https://golang.org/doc/faq#Do_Go_programs_link_with_Cpp_programs) guarantees and inherits the dangers inherit in C
code.

In modern secure software development, it's a [normal](https://www.microsoft.com/security/blog/2009/06/29/static-analysis-tools-and-the-sdl-part-one/) to run static
analysis tools against C code. For example, Clang's scan-build is an excellent,
open-source packaging of Clang's analysis tooling. In a perfect world, running

```
scan-build go build
```

would be enough to perform a scan. In the real world, this doesn't work but this
script works around this limitation.

## Usage

1. Clone the repository
2. In the checkout directory, run
```
./scan.sh <target code> <output directory>

