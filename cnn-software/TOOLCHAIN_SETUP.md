# Building RISCV32IM toolchain from scratch

- Run the following commands (in a Linux environment)

```
# Ubuntu packages needed:
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev \
        libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc zlib1g-dev git libexpat1-dev

sudo mkdir /opt/riscv32im
sudo chown $USER /opt/riscv32im

git clone https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-rv32i
cd riscv-gnu-toolchain-rv32i
git submodule update --init --recursive

mkdir build; cd build
../configure --with-arch=rv32im --prefix=/opt/riscv32im
make -j$(nproc)
```

- This should create a /opt/riscv32im folder with the required toolchain

- Add it to path using the below commands to be able to run it from any directory

```
echo 'export PATH=/opt/riscv32im/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

- Run `riscv32-unknown-elf-gcc  --version` to verify that it is setup correctly.