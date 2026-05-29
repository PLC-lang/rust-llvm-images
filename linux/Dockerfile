ARG DEBIAN_VERSION=trixie
ARG BASE_IMAGE=debian:$DEBIAN_VERSION

FROM $BASE_IMAGE
USER root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

ARG LLVM_VERSION=21
ARG RUST_VERSION=1.95.0

# Install LLVM and its dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        wget curl gnupg build-essential lsb-release ca-certificates git jq \
    && wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key \
        | gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg \
    && CODENAME=$(lsb_release -cs) \
    && echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${LLVM_VERSION} main" \
        > /etc/apt/sources.list.d/llvm.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        clang-${LLVM_VERSION} lld-${LLVM_VERSION} \
        liblld-${LLVM_VERSION}-dev libpolly-${LLVM_VERSION}-dev \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${LLVM_VERSION} 100

# Install llvm-lit, used by our correctness tests
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/
# Use a non root directory for uv
ENV UV_TOOL_DIR="/usr/local/uv"
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
    && rustup target add x86_64-unknown-linux-gnu \
    && rustup target add aarch64-unknown-linux-gnu \
    && rustup target add x86_64-unknown-linux-musl \
    && rustup target add aarch64-unknown-linux-musl

RUN chmod -R a+rw $CARGO_HOME \
    && chmod -R a+rw $RUSTUP_HOME \
    && chmod -R a+rw /usr/local/bin

# Install documentation, coverage, and release tooling
RUN cargo install --locked mdbook grcov cargo-nextest cargo-deb cargo-edit git-cliff

# Configure container defaults for interactive use
WORKDIR /build
ENTRYPOINT ["bash"]

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
