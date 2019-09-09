FROM alpine:3.8 as build

ARG CHROMEOS_VERSION=10895.123.0
ARG KERNEL_UNAME=4.14.91+

RUN apk add --update \
  bison \
  build-base \
  clang-dev \
  clang-static \
  curl \
  cmake \
  elfutils-dev \
  flex-dev \
  git \
  linux-headers \
  llvm5-dev \
  llvm5-static \
  python \
  zlib-dev

# Put LLVM directories where CMake expects them to be
RUN ln -s /usr/lib/cmake/llvm5 /usr/lib/cmake/llvm
RUN ln -s /usr/include/llvm5/llvm /usr/include/llvm
RUN ln -s /usr/include/llvm5/llvm-c /usr/include/llvm-c


RUN mkdir -p /output

WORKDIR /

# Build BCC: https://github.com/iovisor/bcc/blob/master/INSTALL.md#install-and-compile-bcc
# We have to use git rather than the tarball because the build uses git submodules
RUN git clone --branch v0.9.0  https://github.com/iovisor/bcc
WORKDIR /bcc

RUN \
	mkdir build && \
	cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release .. && \
	make -j8 install

# why `make install` doesn't do this, I don't know
RUN cp build/src/cc/lib*.a /usr/lib64

WORKDIR /

# Build bpftrace: https://github.com/iovisor/bpftrace/blob/master/INSTALL.md#ubuntu
RUN git clone https://github.com/iovisor/bpftrace

WORKDIR /bpftrace

# Can't use 0.9.0, https://github.com/iovisor/bpftrace/pull/483
RUN git checkout 5b6352c

# Update linux headers for some missing bpf functions
RUN cp /usr/include/bcc/compat/linux/* /usr/include/linux/

# Build bpftrace
RUN \
	mkdir build && \
	cd build && \
	cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release \
		-DSTATIC_LINKING=ON \
		-DHAVE_BCC_CREATE_MAP=1 \
		-DHAVE_BCC_PROG_LOAD=1 \
		.. && \
	make VERBOSE=1 -j8 bpftrace && \
	make DESTDIR=/output install

# Retrieve the relevant kernel headers
WORKDIR /
RUN mkdir -p /lib/modules/$KERNEL_UNAME/build
RUN curl -O https://storage.googleapis.com/cos-tools/$CHROMEOS_VERSION/kernel-headers.tgz
RUN tar xf kernel-headers.tgz -C /lib/modules/$KERNEL_UNAME/build

# Copy artifacts into final build image
FROM busybox
COPY --from=build /output /
COPY --from=build /lib /
