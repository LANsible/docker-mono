#######################################################################################################################
# Build static Mono
#######################################################################################################################
# NOTE: alpine not working due:
# https://github.com/mono/mono/issues/7167
FROM ubuntu:disco

ENV VERSION=6.6.0.161

# Mono compile requirements:
# https://www.mono-project.com/docs/compiling-mono/linux/
# Added musl for faster and smaller binary
RUN apt-get update && \
  apt-get install -y \
  git \
  autoconf \
  libtool \
  automake \
  build-essential \
  gettext \
  cmake \
  python3 \
  curl \
  linux-headers-$(uname -r) \
  musl-tools

# Download and unpack mono version
RUN mkdir -p mono && \
  curl -L https://download.mono-project.com/sources/mono/mono-${VERSION}.tar.xz \
    | tar -xvJ --strip-components=1 -C mono

WORKDIR /mono

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
# Build minimal mono
# https://github.com/nodejs/node/blob/master/BUILDING.md#building-nodejs-on-supported-platforms
# https://www.mono-project.com/docs/compiling-mono/unsupported-advanced-compile-options/
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  ./configure \
    CC="musl-gcc" \
    CFLAGS="-Wall -O3 -static" \
    LDFLAGS="-static" \
    --prefix=/usr/local \
    --enable-minimal=aot \
    --enable-minimal=profiler \
    --enable-minimal=decimal \
    --enable-minimal=pinvoke \
    --enable-minimal=debug \
    --enable-minimal=reflection_emit \
    --enable-minimal=logging \
    --enable-minimal=com \
    --enable-minimal=generics && \
  make

# # Only run upx when not yet packaged
# # grep on stderr and stdout, therefore the redirect
# # no upx: 43.1M
# # --best: 14.8M
# # brute or ultra-brute stops it from working
# # upx -t to test binary
# RUN if upx -t /root/.nexe/*/out/Release/node 2>&1 | grep -q 'NotPackedException'; then \
#     upx --best /root/.nexe/*/out/Release/node; \
#   fi && \
#   upx -t /root/.nexe/*/out/Release/node
