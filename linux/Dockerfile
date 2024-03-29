ARG DEBIAN_VERSION=bookworm
ARG BASE_IMAGE=debian:$DEBIAN_VERSION

FROM $BASE_IMAGE

# Make sure we are on root
USER root

ARG RUST_VERSION=1.77.0
ARG LLVM_VER=14

# Use the bullseye llvm version because there is no newer one yet
ARG LLVM_DEBIAN_VERSION=bookworm 

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
		&& apt-get upgrade -y \
		&& apt-get install \
			apt-utils	\
			git	\
			wget gnupg curl \
			build-essential \
			libz-dev \
			gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
			-y
# dpkg --add-architecture arm64 \

# # Setup llvm sources
# RUN echo "deb http://apt.llvm.org/$LLVM_DEBIAN_VERSION/ llvm-toolchain-$LLVM_DEBIAN_VERSION-$LLVM_VER  main" >> /etc/apt/sources.list.d/llvm.list
# RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

# RUN apt-get update
#Install Clang dependencies
#On bookworm clang is version 14, which is what we have as default.
#Installing without versions here is convinient for scripts calling clang or lld instead of clang-14/lld-14
RUN apt-get install -y zip clang lldb lld clangd \
	clang-$LLVM_VER lldb-$LLVM_VER lld-$LLVM_VER \
	clangd-$LLVM_VER liblld-$LLVM_VER-dev \
	llvm-$LLVM_VER-dev libpolly-$LLVM_VER-dev

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


RUN chmod -R a+rw $CARGO_HOME \
	&& chmod -R a+rw $RUSTUP_HOME

#Install bininstall to make subsequent binaries easier to download
RUN wget https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-`uname -m`-unknown-linux-musl.tgz && tar -xf cargo-binstall-`uname -m`-unknown-linux-musl.tgz  -C $CARGO_HOME/bin
#Install documentation and coverage tools
RUN cargo binstall --no-confirm mdbook grcov

WORKDIR /build
ENTRYPOINT ["bash"]

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
