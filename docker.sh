#!/bin/bash -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path to go package> <output directory>"
    exit 1
fi

goDir=$(realpath "$1")
outputDir=$(realpath "$2")

[ -d "$outputDir" ] || {
    mkdir -p "$outputDir"
}


imageName="cgo-scan"
tag="latest"

[[ "$(docker images -q "$imageName:$tag" 2> /dev/null)" == "" ]] && {
    docker build -t "$imageName:$tag" .
}

docker run -v "$outputDir":/output -v "$goDir":/code -t "$imageName:$tag" /cgo-scan/scan.sh /code /output


