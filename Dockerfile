# Start with Debian slim image as the base
FROM amd64/debian:stable-slim

# Install system dependencies and create a non-root user 'near'
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
       build-essential \
       ca-certificates \
       pkg-config \
       libudev-dev \
       git \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 near \
    && useradd -m -d /home/near -s /bin/bash -g near -u 1000 near

# Switch to the builder user
USER near

# Set up the environment for the near user with Rust-specific configurations
ARG RUST_VERSION=1.83.0
ENV HOME=/home/near \
    RUSTUP_TOOLCHAIN=$RUST_VERSION \
    RUSTFLAGS='-C link-arg=-s' \
    CARGO_HOME=/home/near/.cargo \
    RUSTUP_HOME=/home/near/.rustup

# Install Rust using rustup with a specific version and add the wasm target
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain $RUST_VERSION -y

# Ensure the Rust and Cargo binaries are in the PATH for easy command-line access
ENV PATH="$CARGO_HOME/bin:$PATH"

# Clone the cargo-near repository and install cargo-near
# tip of pr https://github.com/near/cargo-near/pull/262
ARG CARGO_NEAR_COMMIT=27328252b15d489ab5580a9982d809c961cbeb38

# Add the wasm32-unknown-unknown target and install cargo-near
RUN rustup target add wasm32-unknown-unknown && \
    git clone https://github.com/near/cargo-near.git /home/near/cargo-near \
    && cd /home/near/cargo-near && git checkout $CARGO_NEAR_COMMIT \
    && cd /home/near/cargo-near/cargo-near && cargo install --path . --locked \
    && rm -rf /home/near/cargo-near /home/near/.cargo/registry/cache

# Set appropriate permissions at the end
RUN chmod -R a+rwx $HOME
