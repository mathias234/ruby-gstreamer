#######################
# Builder stage       #
#######################
FROM ubuntu:24.04 AS builder

ARG RUBY_VERSION=3.4.3
ARG GST_VERSION=1.26.1

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Enable universe repository and install build dependencies
RUN apt-get update && apt-get install -y \
  software-properties-common && \
  add-apt-repository universe && \
  apt-get update

RUN apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  wget \
  python3 \
  python3-pip \
  python3-dev \
  gcc \
  clang \
  cmake \
  curl \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libyaml-dev \
  libgmp-dev \
  libffi-dev \
  libatk1.0-dev \
  libatk-bridge2.0-dev \
  libatspi2.0-dev \
  libcups2-dev \
  libxcomposite-dev \
  libxdamage-dev \
  libunwind-dev \
  libdw-dev \
  libgmp-dev \
  libgraphene-1.0-dev \
  libgsl-dev \
  libglib2.0-dev \
  flex \
  bison \
  libcap-dev \
  libgirepository1.0-dev \
  gettext \
  liborc-0.4-dev \
  iso-codes \
  libgl-dev \
  libgles-dev \
  libdrm-dev \
  libgudev-1.0-dev \
  libgbm-dev \
  libpng-dev \
  libjpeg-dev \
  libogg-dev \
  libopus-dev \
  libpango1.0-dev \
  libvisual-0.4-dev \
  libtheora-dev \
  libvorbis-dev \
  libxkbcommon-dev \
  libwayland-dev \
  libepoxy-dev \
  ruby \
  libgcrypt20-dev \
  libwebp-dev \
  libopenjp2-7-dev \
  libwoff-dev \
  libxslt1-dev \
  bubblewrap \
  libseccomp-dev \
  xdg-dbus-proxy \
  gperf \
  libsoup2.4-dev \
  libvulkan-dev \
  libass-dev \
  libchromaprint-dev \
  libcurl4-gnutls-dev \
  libaom-dev \
  libbz2-dev \
  liblcms2-dev \
  libbs2b-dev \
  libdca-dev \
  libfaac-dev \
  libfaad-dev \
  flite1-dev \
  libssl-dev \
  libfdk-aac-dev \
  libfluidsynth-dev \
  libgsm1-dev \
  libkate-dev \
  libgme-dev \
  libde265-dev \
  liblilv-dev \
  libmodplug-dev \
  libmjpegtools-dev \
  libmpcdec-dev \
  libdvdnav-dev \
  libdvdread-dev \
  librsvg2-dev \
  librtmp-dev \
  libsbc-dev \
  libsndfile1-dev \
  libsoundtouch-dev \
  libspandsp-dev \
  libsrt-gnutls-dev \
  libsrtp2-dev \
  libvo-aacenc-dev \
  libvo-amrwbenc-dev \
  libwebrtc-audio-processing-dev \
  libofa0-dev \
  libzvbi-dev \
  libopenexr-dev \
  libwildmidi-dev \
  libx265-dev \
  libzbar-dev \
  wayland-protocols \
  libaa1-dev \
  libmp3lame-dev \
  libcaca-dev \
  libdv4-dev \
  libmpg123-dev \
  libvpx-dev \
  libshout3-dev \
  libspeex-dev \
  libtag1-dev \
  libtwolame-dev \
  libwavpack-dev \
  liba52-0.7.4-dev \
  libx264-dev \
  libopencore-amrnb-dev \
  libopencore-amrwb-dev \
  libmpeg2-4-dev \
  libavcodec-dev \
  libavfilter-dev \
  libavformat-dev \
  libavutil-dev \
  libva-dev \
  libudev-dev \
  glibc-tools \
  libqrencode-dev \
  libjson-glib-dev


# Fetch Ruby source
RUN curl -fsSL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz -o ruby.tar.gz && \
  tar -xzf ruby.tar.gz

# Build and install Ruby
RUN cd ruby-${RUBY_VERSION} && \
  ./configure && make -j$(nproc) && make install

# Install Meson
RUN pip3 install --break-system-packages --no-cache-dir --upgrade meson ninja

# Fetch GStreamer source with submodules
RUN git clone --branch ${GST_VERSION} --depth 1 --recurse-submodules https://gitlab.freedesktop.org/gstreamer/gstreamer.git


ENV MESON_OPTIONS="-Dvaapi=enabled -Dgpl=enabled -Dgst-examples=disabled -Dexamples=disabled -Dtests=disabled -Ddoc=disabled -Dqt5=disabled -Dpython=disabled -Dges=disabled -Ddevtools=disabled -Dlibnice:gupnp=disabled -Dgstreamer-vaapi:x11=disabled -Dgstreamer-vaapi:encoders=enabled"

# Build and install GStreamer
RUN cd gstreamer && \
  meson build -D prefix=/usr ${MESON_OPTIONS} -D buildtype=release -D b_lto=true &&\
  ninja -C build && \
  ninja -C build install && \
  ldconfig


ENV PATH=$PATH:/root/.cargo/bin
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN cargo install cargo-c
RUN git clone --branch 0.13 --depth 1 --recurse-submodules https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
RUN cd gst-plugins-rs
RUN cd gst-plugins-rs && cargo cbuild --prefix=/usr && cargo cinstall --prefix=/usr


#######################
# Final runtime stage #
#######################
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV GST_PLUGIN_SCANNER=/usr/libexec/gstreamer-1.0/gst-plugin-scanner

RUN apt-get update && apt-get install -y \
  software-properties-common && \
  add-apt-repository universe && \
  apt-get update


# Enable universe repository and install runtime dependencies
RUN apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  wget \
  python3 \
  python3-pip \
  python3-dev \
  gcc \
  clang \
  cmake \
  curl \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libyaml-dev \
  libgmp-dev \
  libffi-dev \
  libatk1.0-dev \
  libatk-bridge2.0-dev \
  libatspi2.0-dev \
  libcups2-dev \
  libxcomposite-dev \
  libxdamage-dev \
  libunwind-dev \
  libdw-dev \
  libgmp-dev \
  libgraphene-1.0-dev \
  libgsl-dev \
  libglib2.0-dev \
  flex \
  bison \
  libcap-dev \
  libgirepository1.0-dev \
  gettext \
  liborc-0.4-dev \
  iso-codes \
  libgl-dev \
  libgles-dev \
  libdrm-dev \
  libgudev-1.0-dev \
  libgbm-dev \
  libpng-dev \
  libjpeg-dev \
  libogg-dev \
  libopus-dev \
  libpango1.0-dev \
  libvisual-0.4-dev \
  libtheora-dev \
  libvorbis-dev \
  libxkbcommon-dev \
  libwayland-dev \
  libepoxy-dev \
  ruby \
  libgcrypt20-dev \
  libwebp-dev \
  libopenjp2-7-dev \
  libwoff-dev \
  libxslt1-dev \
  bubblewrap \
  libseccomp-dev \
  xdg-dbus-proxy \
  gperf \
  libsoup2.4-dev \
  libvulkan-dev \
  libass-dev \
  libchromaprint-dev \
  libcurl4-gnutls-dev \
  libaom-dev \
  libbz2-dev \
  liblcms2-dev \
  libbs2b-dev \
  libdca-dev \
  libfaac-dev \
  libfaad-dev \
  flite1-dev \
  libssl-dev \
  libfdk-aac-dev \
  libfluidsynth-dev \
  libgsm1-dev \
  libkate-dev \
  libgme-dev \
  libde265-dev \
  liblilv-dev \
  libmodplug-dev \
  libmjpegtools-dev \
  libmpcdec-dev \
  libdvdnav-dev \
  libdvdread-dev \
  librsvg2-dev \
  librtmp-dev \
  libsbc-dev \
  libsndfile1-dev \
  libsoundtouch-dev \
  libspandsp-dev \
  libsrt-gnutls-dev \
  libsrtp2-dev \
  libvo-aacenc-dev \
  libvo-amrwbenc-dev \
  libwebrtc-audio-processing-dev \
  libofa0-dev \
  libzvbi-dev \
  libopenexr-dev \
  libwildmidi-dev \
  libx265-dev \
  libzbar-dev \
  wayland-protocols \
  libaa1-dev \
  libmp3lame-dev \
  libcaca-dev \
  libdv4-dev \
  libmpg123-dev \
  libvpx-dev \
  libshout3-dev \
  libspeex-dev \
  libtag1-dev \
  libtwolame-dev \
  libwavpack-dev \
  liba52-0.7.4-dev \
  libx264-dev \
  libopencore-amrnb-dev \
  libopencore-amrwb-dev \
  libmpeg2-4-dev \
  libavcodec-dev \
  libavfilter-dev \
  libavformat-dev \
  libavutil-dev \
  libva-dev \
  libudev-dev \
  glibc-tools \
  libqrencode-dev \
  libjson-glib-dev \
  ffmpeg

# Copy compiled binaries and libraries from builder
COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/lib/x86_64-linux-gnu/gstreamer-1.0 /usr/lib/x86_64-linux-gnu/gstreamer-1.0
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgst* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/bin/gst* /usr/bin/
COPY --from=builder /usr/libexec/gstreamer-1.0/gst-plugin-scanner /usr/libexec/gstreamer-1.0/gst-plugin-scanner
COPY --from=builder /usr/lib/x86_64-linux-gnu/pkgconfig/gstreamer* /usr/lib/x86_64-linux-gnu/pkgconfig/

# Update library cache
RUN ldconfig

# Check versions
RUN ruby -v && gst-launch-1.0 --version && ffmpeg -version
