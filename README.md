# rust-llvm-images
Docker images for Rust and LLVM

Allows building Rust applications with the LLVM dependencies on both Windows and Linux

For windows the images have to build locally after accepting the [Visual Studio license](https://go.microsoft.com/fwlink/?LinkId=2086102)

## Building the image
Build the image using 
- Linux or WSL 2 __(Recommended)__: 
	`docker build linux/Dockerfile -t rust-llvm`

- Windows containers :
	`docker build windows/Dockerfile -t rust-llvm`

## Usage

### Direct usage 
Pull the image using 
`docker pull ghcr.io/plc-lang/rust-llvm:latest-linux`

Run with
`docker run -it -v $PWD:/build ghcr.io/plc-lang/rust-llvm:latest-linux`

### Importing

You can import the image into another Dockerfile using
`FROM ghcr.io/plc-lang/rust-llvm:latest-linux`
