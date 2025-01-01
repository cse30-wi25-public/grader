FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# x86 tools
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        sudo ca-certificates vim curl wget git bzip2 file net-tools build-essential less libssl-dev python3 python3-pip \
        qemu-user-static

WORKDIR /

# toolchain & tools symbolic link
RUN curl -L https://static.jyh.sb/source/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz -O && \
    tar -xvf /arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz -C / && \
    mv /arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf /usr/arm-gnu-toolchain && \
    rm /arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz
ENV QEMU_LD_PREFIX=/usr/arm-gnu-toolchain/arm-none-linux-gnueabihf/libc

# wrapper
RUN ln -s /usr/arm-gnu-toolchain/bin/* /usr/bin/ &&\
    mkdir -p /usr/armbin && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-addr2line /usr/armbin/addr2line && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-nm /usr/armbin/nm && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-readelf /usr/armbin/readelf && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-strings /usr/armbin/strings && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-strip /usr/armbin/strip && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-ar /usr/armbin/ar && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-as /usr/armbin/as && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-gcc /usr/armbin/gcc && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-g++ /usr/armbin/g++ && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-cpp /usr/armbin/cpp && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-ld /usr/armbin/ld && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-ranlib /usr/armbin/ranlib && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-gprof /usr/armbin/gprof && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-elfedit /usr/armbin/elfedit && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-objcopy /usr/armbin/objcopy && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-objdump /usr/armbin/objdump && \
    ln -s /usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-size /usr/armbin/size

# valgrind
RUN curl -L https://static.jyh.sb/source/valgrind-3.24.0.tar.bz2 -O && \
    tar -jxf valgrind-3.24.0.tar.bz2
WORKDIR /valgrind-3.24.0
RUN sed -i 's/armv7/arm/g' ./configure && \
    ./configure --host=arm-none-linux-gnueabihf \
                --prefix=/usr/local \
                CFLAGS=-static \
                CC=/usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-gcc \
                CPP=/usr/arm-gnu-toolchain/bin/arm-none-linux-gnueabihf-cpp && \
    make CFLAGS+="-fPIC" && \
    make install
WORKDIR /
RUN rm -rf valgrind-3.24.0 valgrind-3.24.0.tar.bz2 && \
    mv /usr/local/libexec/valgrind/memcheck-arm-linux /usr/local/libexec/valgrind/memcheck-arm-linux-wrapper && \
    echo '#!/bin/bash' > /usr/local/libexec/valgrind/memcheck-arm-linux && \
    echo 'exec qemu-arm-static /usr/local/libexec/valgrind/memcheck-arm-linux-wrapper "$@"' >> /usr/local/libexec/valgrind/memcheck-arm-linux && \
    chmod +x /usr/local/libexec/valgrind/memcheck-arm-linux
ENV VALGRIND_OPTS="--vgdb=no"

# exec hook
COPY hook_execve.c /
RUN QEMU_HASH="$(sha256sum /usr/bin/qemu-arm-static | awk "{print \$1}")" && \
    sed -i "s|PLACEHOLDER_HASH|$QEMU_HASH|g" /hook_execve.c && \
    /usr/bin/gcc -shared -fPIC -o hook_execve.so hook_execve.c -ldl -lssl -lcrypto && \
    mv /hook_execve.so /usr/lib/hook_execve.so && \
    rm /hook_execve.c
ENV LD_PRELOAD /usr/lib/hook_execve.so

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

ENV PATH="/usr/armbin:$PATH"
CMD ["/bin/bash"]
