FROM debian:bookworm-slim AS ffmpeg

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq install --no-install-recommends \
    build-essential \
    git \
    pkg-config \
    yasm \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/FFmpeg/FFmpeg.git --depth 1 --branch n6.1.1 --single-branch /FFmpeg-6.1.1

WORKDIR /FFmpeg-6.1.1

RUN PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
      --prefix="$HOME/ffmpeg_build" \
      --pkg-config-flags="--static" \
      --extra-cflags="-I$HOME/ffmpeg_build/include" \
      --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
      --extra-libs="-lpthread -lm" \
      --ld="g++" \
      --bindir="$HOME/bin" \
      --disable-doc \
      --disable-htmlpages \
      --disable-podpages \
      --disable-txtpages \
      --disable-network \
      --disable-autodetect \
      --disable-hwaccels \
      --disable-ffprobe \
      --disable-ffplay \
      --enable-filter=copy \
      --enable-protocol=file \
      --enable-small && \
    PATH="$HOME/bin:$PATH" make -j$(nproc) && \
    make install && \
    hash -r

FROM python:3.10

WORKDIR /app

COPY . /app
COPY requirements.txt /app
COPY --from=ffmpeg /FFmpeg-6.1.1 /FFmpeg-6.1.1
COPY --from=ffmpeg /root/bin/ffmpeg /usr/local/bin/ffmpeg

RUN pip install --upgrade pip -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
RUN pip install --no-cache-dir -r requirements.txt -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

EXPOSE 8080

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--timeout", "0", "app.webservice:app", "-k", "uvicorn.workers.UvicornWorker"]