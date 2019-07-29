#!/bin/bash -e

shopt -s nullglob

builderName="builder"

# build_helper: this function is called on the second invocation of this
# script. It is used by scan-build as the builder. It builds an object file
# from any C source in the object directory (the output directory from
# go tool cgo).
function build_helper() {
    objectDir=$1
    CCC_CC="$CLANG" "$CC" -I./ "$(tr -d '\n' < "$objectDir"/_CFLAGS)" "$(tr -d '' < "$objectDir"/_LDFLAGS)" -- "$objectDir"/*.{c,cc,cpp,cxx}
    exit $?
}

if [ "$(basename "$0")" == "$builderName" ]; then
    build_helper "$1"
fi



if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path to go package> <output directory>"
    exit 1
fi



srcDir=$1
outputDir="$(realpath "$2")"

# if outputdir does not exist, then create it

[ -d "$outputDir" ] || {
    mkdir -p "$outputDir"
}


tmpDir=$(mktemp -d)

# scriptpath is the directory of this script. We need this as we'll
# be calling ourselves again to run build_helper using a symbolic link
scriptpath="$( cd "$(dirname "$0")" ; pwd -P )/"

pushd "$srcDir"

function cleanup {
    popd
    rm -rf "$tmpDir"
}
trap cleanup EXIT


mapfile -t goFiles < <(go list -f '{{join .CgoFiles "\n"}}')
[ ${#goFiles[@]}  -eq 0 ] && {
    echo "No cgo files found"
    exit 1
}

CC=clang go tool cgo -objdir "$tmpDir" -- "${goFiles[@]}"

function listToFiles() {
    local listName=$1
    local targetDir=$2
    local template
    template="{{join .$listName \"\\n\"}}"
    mapfile -t array < <(go list -f "$template")
    [ ${#array[@]} -eq 0 ] || cp -- "${array[@]}" "$targetDir"
}

# make sure any C/C++ files which would be compiled with "go build"
# are present
listToFiles "CFiles" "$tmpDir"
listToFiles "CXXFiles" "$tmpDir"
listToFiles "HFiles" "$tmpDir"
# any .pc files for package config
pcFiles=(*.pc)
[ ${#pcFiles[@]} -eq 0 ] || cp -- "${pcFiles[@]}" "$tmpDir"

# write out any CFLAGS, linker flags etc so we can use them in the build

go list -f '{{join .CgoCFLAGS "\n"}}' > "$tmpDir"/_CFLAGS
{ go list -f '{{join .CgoCPPFLAGS "\n"}}'; go list -f '{{join .CgoCXXFLAGS "\n"}}'; } >> "$tmpDir"/_CFLAGS
go list -f '{{join .CgoLDFLAGS "\n"}}' >> "$tmpDir"/_LDFLAGS

for pkgConfig in $(go list -f '{{join .CgoPkgConfig "\n"}}'); do
    pkg-config --libs "$pkgConfig" >> "$tmpDir"/_LDFLAGS
    pkg-config --cflags "$pkgConfig" >> "$tmpDir"/_CFLAGS
done



scan-build -o "$outputDir" \
    -enable-checker alpha.core.CastSize \
    -enable-checker alpha.core.CastToStruct \
    -enable-checker alpha.core.IdenticalExpr \
    -enable-checker alpha.core.SizeofPtr \
    -enable-checker alpha.security.ArrayBoundV2 \
    -enable-checker alpha.security.MallocOverflow \
    -enable-checker alpha.security.ReturnPtrRange \
    -enable-checker alpha.unix.SimpleStream \
    -enable-checker alpha.unix.cstring.BufferOverlap \
    -enable-checker alpha.unix.cstring.NotNullTerminated \
    -enable-checker alpha.unix.cstring.OutOfBounds \
    -enable-checker alpha.core.FixedAddr \
    -enable-checker security.insecureAPI.gets \
    -enable-checker security.insecureAPI.rand \
    -enable-checker security.insecureAPI.strcpy \
    -enable-checker security.insecureAPI.vfork \
    "$scriptpath/$builderName" "$tmpDir"
