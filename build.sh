#/bin/bash

# clean
rm -rf build
rm -f libtex3ds.a

# build lib
mkdir -p build
cmake -S . -B build
make -C build

# copy lib to current directory
cp build/libtex3ds.a ./
