# Start with Debian slim image as the base
FROM amd64/debian:stable-slim as build-production

# Install system dependencies and create a non-root user 'near'
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git \
       curl \
       build-essential \
       ca-certificates \
       pkg-config \
       libudev-dev \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 near \
    && useradd -m -d /home/near -s /bin/bash -g near -u 1000 near

# Switch to the near user
USER near

# Set up the environment for the near user with Rust-specific configurations
ARG RUST_VERSION=1.79.0
ENV HOME=/home/near \
    RUSTUP_TOOLCHAIN=$RUST_VERSION \
    RUSTFLAGS='-C link-arg=-s' \
    CARGO_HOME=/home/near/.cargo \
    RUSTUP_HOME=/home/near/.rustup

# Install Rust using rustup with a specific version, add the wasm target, install cargo-near, and set directory permissions
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain $RUST_VERSION -y \
    && chmod -R a+rwx $CARGO_HOME $RUSTUP_HOME

# Ensure the Rust and Cargo binaries are in the PATH for easy command-line access
ENV PATH="$CARGO_HOME/bin:$PATH"

# Continuation of the Rust setup: adding the wasm target for WebAssembly development and installing cargo-near for NEAR protocol development, followed by setting appropriate permissions for the near's home directory
RUN rustup target add wasm32-unknown-unknown \
    && chmod -R a+rwx $HOME

ARG CARGO_NEAR_COMMIT=a04e05ea700cecdaba0d29f54db8820055a65d0d

RUN git clone https://github.com/near/cargo-near.git /home/near/cargo-near \
    && cd /home/near/cargo-near && git checkout $CARGO_NEAR_COMMIT 

RUN cd /home/near/cargo-near/cargo-near && cargo install --path . --locked && rm -rf /cargo-near/target

# /home/near/.cargo/registry/cache was created during bulding `cargo-near`
# this may be inaccessible for users other than near
RUN chmod -R a+rwx $CARGO_HOME
