#!/usr/bin/env bash

format_time() {
    local T=$1
    local H=$((T/3600))
    local M=$(( (T%3600)/60 ))
    local S=$((T%60))
    if [ "$H" -gt 0 ]; then
        echo "${H}h${M}m${S}s"
    elif [ "$M" -gt 0 ]; then
        echo "${M}m${S}s"
    else
        echo "${S}s"
    fi
}

package_dir() {
    local src="$1"
    local dest="$2"
    (cd "$src" && zip -r "$dest" .)
}

complete_build() {
    local toolchain="$1"
    local build_dir="$2"

    local binary_dir="$build_dir/bin"
    local strip="$toolchain/bin/strip"

    declare -a build_tools=(aapt aapt2 aidl zipalign dexdump split-select)
    declare -a platform_tools=(sqlite3 etc1tool hprof-conv e2fsdroid sload_f2fs mke2fs make_f2fs make_f2fs_casefold)
    declare -a other_tools=(veridex)

    for dir in build-tools platform-tools others; do
        mkdir -p "$binary_dir/$dir"
    done

    for tool in "${build_tools[@]}"; do
        if [ -f "$binary_dir/$tool" ]; then
            cp "$binary_dir/$tool" "$binary_dir/build-tools/"
            rm "$binary_dir/$tool"
            "$strip" -g "$binary_dir/build-tools/$tool"
        fi
    done

    for tool in "${platform_tools[@]}"; do
        if [ -f "$binary_dir/$tool" ]; then
            cp "$binary_dir/$tool" "$binary_dir/platform-tools/"
            rm "$binary_dir/$tool"
            "$strip" -g "$binary_dir/platform-tools/$tool"
        fi
    done

    for tool in "${other_tools[@]}"; do
        if [ -f "$binary_dir/$tool" ]; then
            cp "$binary_dir/$tool" "$binary_dir/others/"
            rm "$binary_dir/$tool"
            "$strip" -g "$binary_dir/others/$tool"
        fi
    done

  # package_dir "$binary_dir" "$build_dir/android-sdk-tools-${arch_map[$abi]}.zip"
}

build() {
    local toolchain="$1"
    local build_dir="$2"
    local jobs="$3"
    local target="$4"
    local protoc="$5"
    local cmd=(
        cmake -GNinja
        -B "$build_dir"
        -DCMAKE_SYSTEM_NAME=Linux
        -DCMAKE_CROSSCOMPILING=True
        -DCMAKE_PREFIX_PATH="$(pwd)/extrabuild"
        -DCMAKE_C_COMPILER="$toolchain/bin/cc"
        -DCMAKE_CXX_COMPILER="$toolchain/bin/c++"
        -DCMAKE_ASM_COMPILER="$toolchain/bin/cc"
        -DCMAKE_LINKER="$toolchain/bin/ld"
        -DCMAKE_OBJCOPY="$toolchain/bin/objcopy"
        -DCMAKE_AR="$toolchain/bin/ar"
        -DCMAKE_STRIP="$toolchain/bin/strip"
        -DCMAKE_C_FLAGS="-fsanitize=undefined -DPNG_ARM_NEON_OPT=0 -UPNG_ARM_NEON_IMPLEMENTATION -U__BIONIC__ -Wno-error=date-time -Doff64_t=off_t -Dmmap64=mmap -Dlseek64=lseek -Dpread64=pread -Dpwrite64=pwrite -Dftruncate64=ftruncate -DANDROID_HOST_MUSL -static"
        -DCMAKE_CXX_FLAGS="-fsanitize=undefined -DPNG_ARM_NEON_OPT=0 -UPNG_ARM_NEON_IMPLEMENTATION -U__BIONIC__ -Wno-error=date-time -Doff64_t=off_t -Dmmap64=mmap -Dlseek64=lseek -Dpread64=pread -Dpwrite64=pwrite -Dftruncate64=ftruncate -DANDROID_HOST_MUSL -static"
        -DCMAKE_EXE_LINKER_FLAGS="-static"
        -Dprotobuf_BUILD_TESTS=OFF
        -DABSL_PROPAGATE_CXX_STD=ON
        -DCMAKE_BUILD_TYPE=MinSizeRel
        -DPROTOC_PATH=$protoc
    )

    "${cmd[@]}"

    local start_time=$(date +%s)

    if [ "$target" = "all" ]; then
        ninja -C "$build_dir" -j "$jobs"
    else
        ninja -C "$build_dir" "$target" -j "$jobs"
    fi

    if [ $? -ne 0 ]; then
        echo -e "\033[1;31mBuild failed!\033[0m"
        exit 1
    fi

    complete_build "$toolchain" "$build_dir"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo -e "\033[1;32mbuild success cost time: $(format_time "$duration")\033[0m"
}

build $1 "build" "$(nproc)" "all" $2
