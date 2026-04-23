#!/bin/bash
TARGET="${1:-native}"
BUILD_DIR="build"

rm -rf "${BUILD_DIR}" libtex3ds.a libtex3ds.h

if [ "${TARGET}" = "3ds" ]; then
    cmake -S . -B "${BUILD_DIR}" \
        -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/3DS.cmake \
        -DCMAKE_BUILD_TYPE=Release
else
    cmake -S . -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
fi

cmake --build "${BUILD_DIR}"
cp "${BUILD_DIR}/libtex3ds.a" ./
cp "${BUILD_DIR}/libtex3ds.a" ./example
cp public/libtex3ds.h ./
cp public/libtex3ds.h ./example
