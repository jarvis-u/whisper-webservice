FROM centos:7 AS ffmpeg

RUN dnf makecache && \
    yum update -y && \
    yum install -y \
    epel-release \
    git \
    gcc \
    make \
    yasm \
    ca-certificates \
    && yum clean all

COPY FFmpeg/ /FFmpeg-6.1.1

WORKDIR /FFmpeg-6.1.1

RUN ./configure \
      --prefix="/usr/local/ffmpeg_build" \
      --pkg-config-flags="--static" \
      --extra-cflags="-I/usr/local/ffmpeg_build/include" \
      --extra-ldflags="-L/usr/local/ffmpeg_build/lib" \
      --extra-libs="-lpthread -lm" \
      --ld="g++" \
      --bindir="/usr/local/bin" \
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
    make -j$(nproc) && \
    make install && \
    hash -r

FROM centos:7

WORKDIR /app

COPY app/ /app
COPY requirements.txt /app
COPY --from=ffmpeg /FFmpeg-6.1.1 /FFmpeg-6.1.1
COPY --from=ffmpeg /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

RUN yum update -y && \
    yum install -y \
    python3 \
    python3-pip \
    && yum clean all

RUN pip install --upgrade pip -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
RUN pip install --no-cache-dir -r requirements.txt -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

EXPOSE 8080

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--timeout", "0", "app.webservice:app", "-k", "uvicorn.workers.UvicornWorker"]