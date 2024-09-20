#!/bin/bash
set -eu

function has_built_uboot() {
	if [ -f $1/uboot.img ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel() {
	local KIMG=kernel.img
	if [ -f $1/${KIMG} ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel_modules() {
	local OUTDIR=${2}
	local SOC=rk3568
	if [ -d ${OUTDIR}/output_${SOC}_kmodules ]; then
		echo 1
	else
		echo 0
	fi
}

function check_and_install_package() {
	local PACKAGES=
	if ! command -v mkfs.exfat &>/dev/null; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			noble | jammy | bookworm | bullseye)
				PACKAGES="exfatprogs ${PACKAGES}"
				;;
			*)
				PACKAGES="exfat-fuse exfat-utils ${PACKAGES}"
				;;
			esac
		fi

	fi
	if ! [ -x "$(command -v simg2img)" ]; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			focal | jammy | noble | bookworm | bullseye)
				PACKAGES="android-sdk-libsparse-utils ${PACKAGES}"
				# PACKAGES="android-sdk-ext4-utils ${PACKAGES}"
				;;
			*)
				PACKAGES="android-tools-fsutils ${PACKAGES}"
				;;
			esac
		fi
	fi
	if ! [ -x "$(command -v swig)" ]; then
		PACKAGES="swig ${PACKAGES}"
	fi
	if ! [ -x "$(command -v git)" ]; then
		PACKAGES="git ${PACKAGES}"
	fi
	if ! [ -x "$(command -v wget)" ]; then
		PACKAGES="wget ${PACKAGES}"
	fi
	if ! [ -x "$(command -v rsync)" ]; then
		PACKAGES="rsync ${PACKAGES}"
	fi
	if ! command -v partprobe &>/dev/null; then
		PACKAGES="parted ${PACKAGES}"
	fi
	if ! command -v sfdisk &>/dev/null; then
		PACKAGES="fdisk ${PACKAGES}"
	fi
	if ! command -v resize2fs &>/dev/null; then
		PACKAGES="e2fsprogs ${PACKAGES}"
	fi
	if ! command -v mkfs.btrfs &>/dev/null; then
		PACKAGES="btrfs-progs ${PACKAGES}"
	fi
	if [ ! -z "${PACKAGES}" ]; then
		sudo apt install ${PACKAGES}
	fi
}

function check_and_install_toolchain() {
	local PACKAGES=
	local requirements=("build-essential" "make" "device-tree-compiler" "bc" "cpio" "lz4"
		"flex" "bison" "libncurses-dev" "libssl-dev" "libelf-dev")
	for pkg in ${requirements[@]}; do
		if ! dpkg -s $pkg >/dev/null 2>&1; then
			PACKAGES="$pkg ${PACKAGES}"
		fi
	done
	if [ ! -z "${PACKAGES}" ]; then
		sudo apt install ${PACKAGES}
	fi
	local file_path=$(realpath $0)
	local tools_path=$(dirname $file_path)
	local project_root_path=$(realpath $tools_path/../..)
	local prebuilts_gcc_aarch64_path="${project_root_path}/prebuilts/gcc/linux-x86/aarch64/gcc-arm-11.3-x86_64-aarch64-none-linux-gnu"
	case "$(uname -mpi)" in
	x86_64*)
		if [ ! -d $prebuilts_gcc_aarch64_path ]; then
			echo "please install aarch64-gcc-11.3 first."
			exit 1
		fi
		export PATH=$prebuilts_gcc_aarch64_path/bin/:$PATH
		echo "tools: command 'export PATH=$prebuilts_gcc_aarch64_path/bin/:\$PATH'"
		return 0
		;;
	aarch64*)
		return 0
		;;
	*)
		echo "Error: Cannot build arm64 arch on $(uname -mpi) host."
		;;
	esac
	return 1
}
