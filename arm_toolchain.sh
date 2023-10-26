#!/bin/bash
# Setup toolchain files that are required to build InfiniTime with WLLVM
#
# Usage:
# ./init_infinitime_toolchain.sh <dir to install toolchain> <llvm dir> [path to further tools (optional)]
#
# The default <dir to install toolchain> is ~/infinitime_toolchain_dir
# The default <llvm dir> is /usr
#
# Recommend to use the run target init_infinitime_toolchain instead of calling this script by your own

# Stop this script on error
set -e

print("TODO: untested, integrate in meson")
exit 42

# retrieve commandline arguments
readonly TOOLCHAIN_DIR=${1:-~/infinitime_toolchain_dir}
readonly HOST_LLVM_TOOLCHAIN_DIR=${2:-/usr}
readonly GIT=${3:-git}
readonly WGET=${4:-wget}
readonly TAR=${5:-tar}
readonly UNZIP=${6:-unzip}
readonly PYTHON=${7:-python3}
readonly SHA256SUM=${8:-sha256sum}
readonly REALPATH=${9:-realpath}

readonly ORIG_WORK_DIR=$(dirname $(${REALPATH} "$0"))

mkdir -p ${TOOLCHAIN_DIR}
cd ${TOOLCHAIN_DIR}

check_hash_of_file()
{
	local hash_filename="${1}.sha256"
	cp "${ORIG_WORK_DIR}/${hash_filename}" "${hash_filename}"
	${SHA256SUM} -c "${hash_filename}"
	rm "${hash_filename}"
}

# Install LLVM ARM Toolchain
${WGET} "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/archive/refs/tags/release-14.0.0.tar.gz" -O release-14.0.0.tar.gz
check_hash_of_file release-14.0.0.tar.gz
${TAR} -xzf release-14.0.0.tar.gz
rm release-14.0.0.tar.gz
cd LLVM-embedded-toolchain-for-Arm-release-14.0.0
./setup.sh
. venv/bin/activate
build.py --install-dir ${TOOLCHAIN_DIR}/arm-llvm-14 --host-toolchain-dir ${HOST_LLVM_TOOLCHAIN_DIR}/bin --native-toolchain-dir ${HOST_LLVM_TOOLCHAIN_DIR}/bin --use-ninja
deactivate
cd ..
rm LLVM-embedded-toolchain-for-Arm-release-14.0.0 -rf
# fix libclang_rt.builtins-arm naming issue
cd arm-llvm-14/LLVMEmbeddedToolchainForArm-14.0.0/lib/clang-runtimes/armv7em_hard_fpv5_d16/lib
ln -s libclang_rt.builtins-armv7em.a libclang_rt.builtins-arm.a
cd ../../../../../../

# Download arm-none-eabi toolchain
${WGET} "https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz?rev=7bd049b7a3034e64885fa1a71c12f91d&hash=2C60D7D4E432953DB65C4AA2E7129304F9CD05BF" -O arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz
check_hash_of_file arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz
${WGET} "https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc?rev=abe4517f445d4540b9eb8beec2ae59f5&hash=ED658E04D362063A633F21DF0525B3C3BE176C50" -O arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
${SHA256SUM} -c arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
rm arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz.sha256asc
${TAR} -xf arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz
rm arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz

