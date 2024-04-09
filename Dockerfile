# Start with Debian slim image as the base
FROM amd64/debian:stable-slim

# Install system dependencies and create a non-root user 'builder'
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
       build-essential \
       ca-certificates \
       pkg-config \
       libudev-dev \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 builder \
    && useradd -m -d /home/builder -s /bin/bash -g builder -u 1000 builder

# Switch to the builder user
USER builder

# Set up the environment for the builder user with Rust-specific configurations
ENV HOME=/home/builder \
    RUSTUP_TOOLCHAIN=1.75 \
    RUSTFLAGS='-C link-arg=-s' \
    CARGO_NEAR_NO_REPRODUCIBLE=true \
    CARGO_HOME=/home/builder/.cargo \
    RUSTUP_HOME=/home/builder/.rustup

# Install Rust using rustup with a specific version, add the wasm target, install cargo-near, and set directory permissions
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain 1.75.0 -y \
    && chmod -R a+rwx $CARGO_HOME $RUSTUP_HOME

# Ensure the Rust and Cargo binaries are in the PATH for easy command-line access
ENV PATH="$CARGO_HOME/bin:$PATH"

# Continuation of the Rust setup: adding the wasm target for WebAssembly development and installing cargo-near for NEAR protocol development, followed by setting appropriate permissions for the builder's home directory
RUN rustup target add wasm32-unknown-unknown \
    && chmod -R a+rwx $HOME

ADD --chown=builder:builder cargo-near /cargo-near

RUN cd /cargo-near/cargo-near && cargo install --path . --locked && rm -rf /cargo-near/target

# /home/builder/.cargo/registry/cache was created during bulding `cargo-near`
# this may be inaccessible for users other than builder
RUN chmod -R a+rwx $CARGO_HOME
