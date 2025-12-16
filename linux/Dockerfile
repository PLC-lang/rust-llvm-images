ARG DEBIAN_VERSION=bookworm
ARG BASE_IMAGE=debian:$DEBIAN_VERSION

FROM $BASE_IMAGE
USER root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

ARG LLVM_VERSION=21
ARG RUST_VERSION=1.90

# Install LLVM and its dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends wget curl gnupg build-essential lsb-release software-properties-common \
    && wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh $LLVM_VERSION \
    && apt install -y --no-install-recommends clang lld liblld-$LLVM_VERSION-dev libpolly-$LLVM_VERSION-dev

# TODO: Remove this once we completely switched over to LLVM 21
RUN apt install -y zip clang lldb lld clangd clang-14 lldb-14 lld-14 clangd-14 liblld-14-dev llvm-14-dev libpolly-14-dev

# Install llvm-lit, used by our correctness tests
COPY --from=ghcr.io/astral-sh/uv:0.9.17 /uv /uvx /bin/
ENV UV_TOOL_BIN_DIR="/usr/local/bin/"
RUN uv tool install lit

# Install Rust
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup

RUN curl https://sh.rustup.rs -sSf | bash -s -- --profile minimal --default-toolchain none -y
ENV PATH="${CARGO_HOME}/bin:${PATH}"

RUN rustup toolchain install $RUST_VERSION \
    && rustup default $RUST_VERSION \
    && rustup component add clippy rustfmt llvm-tools-preview \
    && rustup target add aarch64-unknown-linux-gnu \
    && rustup target add x86_64-unknown-linux-musl

RUN chmod -R a+rw $CARGO_HOME \
    && chmod -R a+rw $RUSTUP_HOME \
    && chmod -R a+rw /usr/local/bin

# Install cargo-binstall to make subsequent binaries easier to download
RUN wget https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-$(uname -m)-unknown-linux-musl.tgz \
    && tar -xf cargo-binstall-$(uname -m)-unknown-linux-musl.tgz -C $CARGO_HOME/bin \
    && rm cargo-binstall-*.tgz

RUN cargo binstall --no-confirm mdbook grcov cargo-nextest

# Configure container defaults for interactive use
WORKDIR /build
ENTRYPOINT ["bash"]

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
