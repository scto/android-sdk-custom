# Android SDK Custom

A custom-built Android SDK that replaces the default binaries with versions built using **musl libc from [Zig](https://ziglang.org)**. Inspired by [lzhiyong's Android SDK Tools](https://github.com/lzhiyong/android-sdk-tools).

## Features

- **Custom-built binaries**, sourced from Google's Android SDK repositories.
- Uses **Zig** as a build environment for musl-based toolchains.

## Architecture and Platform Support

- **Zig-based Environment**
  - **Supported Platforms**:
    - Linux
    - Android
  - **Supported Architectures**:
    - **x86**: `x86`, `x86_64`
    - **ARM**: `arm`, `armhf`, `aarch64`
    - **RISC-V**: `riscv64`

## Usage

This SDK functions like the standard Android SDK. Simply extract the archive and use it as you would the official version.

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.

---

Feel free to open pull requests or issues if you have any contributions or feedback!
