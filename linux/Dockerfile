ARG DEBIAN_VERSION=bullseye
ARG BASE_IMAGE=debian:$DEBIAN_VERSION

FROM $BASE_IMAGE

# Make sure we are on root
USER root

ARG RUST_VERSION=1.67.0
ARG LLVM_VER=14

# Use the bullseye llvm version because there is no newer one yet
ARG LLVM_DEBIAN_VERSION=bullseye 

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture arm64 \
		&& apt-get update \
		&& apt-get install \
			apt-utils	\
			wget gnupg curl \
			build-essential \
			libz-dev \
			gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
			-y

# Setup llvm sources
RUN echo "deb http://apt.llvm.org/$LLVM_DEBIAN_VERSION/ llvm-toolchain-$LLVM_DEBIAN_VERSION-$LLVM_VER  main" >> /etc/apt/sources.list.d/llvm.list
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

RUN apt-get update
#Install Clang dependencies
RUN apt-get install -y zip clang-$LLVM_VER lldb-$LLVM_VER lld-$LLVM_VER clangd-$LLVM_VER liblld-$LLVM_VER-dev llvm-$LLVM_VER-dev

ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- --profile minimal --default-toolchain none -y
ENV PATH="${CARGO_HOME}/bin:${PATH}"

RUN rustup toolchain install nightly  \
		&& rustup toolchain install $RUST_VERSION \
		&& rustup default $RUST_VERSION \
		&& rustup component add clippy rustfmt llvm-tools-preview  \
		&& rustup component add --toolchain nightly llvm-tools-preview  \
		&& rustup target add aarch64-unknown-linux-gnu \ 
		&& rustup target add x86_64-unknown-linux-musl 
#Install documentation and coverage tools
RUN cargo install mdbook grcov

WORKDIR /build
ENTRYPOINT ["bash"]

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
