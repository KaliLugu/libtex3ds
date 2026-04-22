#/bin/bash

# clean
rm -rf build
rm -f libtex3ds.a
rm -f libtex3ds.h
rm -f example/libtex3ds.a
rm -f example/libtex3ds.h

# build lib
mkdir -p build
cmake -S . -B build
make -C build

# copy lib to current directory
cp build/libtex3ds.a ./
cp build/libtex3ds.a ./example
cp public/libtex3ds.h ./
cp public/libtex3ds.h ./example
