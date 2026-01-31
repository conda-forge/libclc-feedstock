#!/bin/bash
set -ex

mkdir build
cd build

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  mkdir -p native-build
  cd native-build

  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=${CC_FOR_BUILD} \
    -DCMAKE_CXX_COMPILER=${CXX_FOR_BUILD} \
    -DCMAKE_PREFIX_PATH=${BUILD_PREFIX} \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,${BUILD_PREFIX}/lib" \
    -DLLVM_DIR=${BUILD_PREFIX}/lib/cmake/llvm \
    ../..
  make prepare_builtins -j${CPU_COUNT}

  PREPARE_BUILTINS_PATH="$(pwd)/prepare_builtins"
  cd ..

  export CMAKE_ARGS="${CMAKE_ARGS} -Dprepare_builtins_exe=${PREPARE_BUILTINS_PATH}"
  # Ensure install prefix is set (CMAKE_ARGS may not include it without compiler toolchain)
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${PREFIX}"
  # Use native LLVM tools (clang, llvm-as, etc.) from BUILD_PREFIX
  export CMAKE_ARGS="${CMAKE_ARGS} -DLIBCLC_CUSTOM_LLVM_TOOLS_BINARY_DIR=${BUILD_PREFIX}/bin"
  # llvm-spirv is not covered by LIBCLC_CUSTOM_LLVM_TOOLS_BINARY_DIR, pass it directly
  export CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_SPIRV=${BUILD_PREFIX}/bin/llvm-spirv"
fi

cmake \
	${CMAKE_ARGS} \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_MODULE_PATH=${PREFIX}/lib/cmake/llvm \
	-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
	..

make -j${CPU_COUNT}
make install
