ARG VERSION=latest
FROM ghcr.io/plc-lang/rust-llvm:$VERSION

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN cargo binstall cargo-insta cargo-watch

ENV DEBIAN_FRONTEND=dialog