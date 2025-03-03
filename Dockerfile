FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y --fix-missing \
    git \
    lsb-release \
    python3 \
    python3-pip \
    autoconf \
    bc \
    bison \
    dos2unix \
    gdb \
    gcc \
    lcov \
    make \
    flex \
    build-essential \
    ca-certificates \
    curl \
    device-tree-compiler \
    lcov \
    unzip \
    nano

# Install RISC-V Toolchain
WORKDIR /tmp
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; arch="${arch##*-}"; \
    url=; \
    case "$arch" in \
    'arm64') \
    curl --output riscv-gnu-toolchain.tar.gz -L "https://github.com/langproc/langproc-2022-cw/releases/download/v1.0.0/riscv-gnu-toolchain-2022-09-21-ubuntu-22.04-arm64.tar.gz" \
    ;; \
    *) curl --output riscv-gnu-toolchain.tar.gz -L "https://github.com/langproc/langproc-2022-cw/releases/download/v1.0.0/riscv-gnu-toolchain-2022-09-21-ubuntu-22.04-amd64.tar.gz" \
    ;; \
    esac;
RUN rm -rf /opt/riscv
RUN tar -xzf riscv-gnu-toolchain.tar.gz --directory /opt
ENV PATH="/opt/riscv/bin:${PATH}"
ENV RISCV="/opt/riscv"
RUN rm -rf riscv-gnu-toolchain.tar.gz
RUN riscv64-unknown-elf-gcc --help

# Install Spike RISC-V ISA Simulator
WORKDIR /tmp
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git
WORKDIR /tmp/riscv-isa-sim
RUN git checkout v1.1.0
RUN mkdir build
WORKDIR /tmp/riscv-isa-sim/build
RUN ../configure --prefix=$RISCV --with-isa=RV32IMFD --with-target=riscv32-unknown-elf
RUN make
RUN make install
RUN rm -rf /tmp/riscv-isa-sim
RUN spike --help

WORKDIR /tmp
RUN git clone https://github.com/riscv-software-src/riscv-pk.git
WORKDIR /tmp/riscv-pk
RUN git checkout 573c858d9071a2216537f71de651a814f76ee76d
RUN mkdir build
WORKDIR /tmp/riscv-pk/build
RUN ../configure --prefix=$RISCV --host=riscv64-unknown-elf --with-arch=rv32imfd --with-abi=ilp32d
RUN make
RUN make install

# Install compiler explorer
RUN git clone https://github.com/compiler-explorer/compiler-explorer.git /workspaces/compiler-explorer

 # script that finds and runs compiler
RUN echo 'exec "$(find /workspaces -maxdepth 1 -type d -name "langproc*" | head -n 1)/scripts/run.sh" "$@"' > /workspaces/compiler-run.sh && \
    chmod +x /workspaces/compiler-run.sh

EXPOSE 10240

# Install fnm
RUN curl -fsSL https://fnm.vercel.app/install | bash

# compiler-explorer config
RUN echo ' \n\
        group.langproc.compilers=clangprocdefault \n\
        compiler.clangprocdefault.exe=/workspaces/compiler-run.sh \n\
        compiler.clangprocdefault.name=langproc' >> /workspaces/compiler-explorer/etc/config/c.defaults.properties

RUN cp /workspaces/compiler-explorer/etc/config/c.defaults.properties /tmp/props \
    && echo 'compilers=&gcc:&clang:&langproc' > /workspaces/compiler-explorer/etc/config/c.defaults.properties \
    && tail +3 /tmp/props >> /workspaces/compiler-explorer/etc/config/c.defaults.properties


ENTRYPOINT [ "/bin/bash" ]
