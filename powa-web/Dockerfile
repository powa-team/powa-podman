#vim:set ft=dockerfile
FROM debian:stretch-slim
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
    libpq5 \
    libpq-dev \
    python \
    python-dev \
    python-pip \
    # current released version is not compatible with SQLAlchemy >= 3.0.0
    && pip install "sqlalchemy<1.3.0" \
    && pip install powa-web \
    && apt-get purge -y --auto-remove libpq-dev python-dev python-pip \
    && rm -rf /var/lib/apt/lists/*

COPY powa-web.conf /etc/

EXPOSE 8888
CMD ["powa-web"]
