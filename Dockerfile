FROM golang
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y clang clang-tools
RUN mkdir /cgo-scan
COPY scan.sh /cgo-scan
COPY builder /cgo-scan
