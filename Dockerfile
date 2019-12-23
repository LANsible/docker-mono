#######################################################################################################################
# Build static Mono
#######################################################################################################################
FROM alpine:3.11

# 6.6 does not build:
# https://github.com/mono/mono/issues/7167
ENV VERSION=6.4.0.198

# Added busybox-static for easy usage in scratch images
RUN apk --no-cache add \
  git \
  autoconf \
  libtool \
  automake \
  build-base \
  gettext \
  cmake \
  python3 \
  curl \
  linux-headers \
  busybox-static

# Download and unpack mono version
RUN mkdir -p mono && \
  wget -O - https://download.mono-project.com/sources/mono/mono-${VERSION}.tar.xz \
    | tar -xJ --strip-components=1 -C mono

WORKDIR /mono

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
# Symlink is needed until:
# https://github.com/mono/mono/pull/18197 is released
# Build minimal mono
# https://github.com/nodejs/node/blob/master/BUILDING.md#building-nodejs-on-supported-platforms
# https://www.mono-project.com/docs/compiling-mono/unsupported-advanced-compile-options/
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  ln -sf /usr/bin/python3 /usr/bin/python && \
  ./configure \
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
