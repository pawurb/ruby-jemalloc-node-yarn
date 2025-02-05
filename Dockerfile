FROM ubuntu:22.04 AS builder

ENV MIRROR="mirrors.ocf.berkeley.edu"

RUN sed -i "s|deb.debian.org|$MIRROR|g" /etc/apt/sources.list \
  && apt-get update \
  && apt-get -y upgrade \
  && apt-get -y install wget \
  && apt-get -y remove --purge wget \
  && apt-get -y autoremove --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  bzip2 \
  ca-certificates \
  openssl \
  curl \
  libffi-dev \
  libssl-dev \
  libyaml-dev \
  libxml2 \
  libxml2-dev \
  libpq-dev \
  libxslt1-dev \
  procps \
  zlib1g-dev \
  libjemalloc-dev \
  imagemagick \
  && rm -rf /var/lib/apt/lists/*

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
  echo 'install: --no-document'; \
  echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 3.3
ENV RUBY_VERSION 3.3.5
ENV RUBY_DOWNLOAD_SHA256 3781a3504222c2f26cb4b9eb9c1a12dbf4944d366ce24a9ff8cf99ecbce75196
ENV RUBYGEMS_VERSION 3.5.16

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN set -ex \
  && buildDeps=' \
  autoconf \
  bison \
  gcc \
  libbz2-dev \
  libgdbm-dev \
  libglib2.0-dev \
  libncurses-dev \
  libreadline-dev \
  libxml2-dev \
  libxslt-dev \
  make \
  ruby \
  ' \
  && apt-get update \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fSL -o ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/ruby \
  && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.gz \
  && cd /usr/src/ruby \
  && { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new && mv file.c.new file.c \
  && autoconf \
  && ./configure --with-jemalloc --disable-install-doc \
  && make -j"$(nproc)" \
  && make install \
  && apt-get purge -y --auto-remove $buildDeps \
  && gem update --system $RUBYGEMS_VERSION \
  && rm -r /usr/src/ruby

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN gem install bundler -v 2.5.20
RUN apt-get update
RUN apt-get -y install curl
RUN apt-get install -my gnupg
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get -qqyy install nodejs yarn && rm -rf /var/lib/apt/lists/*

RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y openssl libpq-dev build-essential libcurl4-openssl-dev software-properties-common

# Download & extract & make libsodium
ENV LIBSODIUM_VERSION 1.0.20
RUN apt-get install build-essential
RUN \
  mkdir -p /tmpbuild/libsodium && \
  cd /tmpbuild/libsodium && \
  curl -L https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VERSION}.tar.gz -o libsodium-${LIBSODIUM_VERSION}.tar.gz && \
  tar xfvz libsodium-${LIBSODIUM_VERSION}.tar.gz && \
  cd /tmpbuild/libsodium/libsodium-${LIBSODIUM_VERSION}/ && \
  ./configure && \
  make && make check && \
  make install && \
  mv src/libsodium /usr/local/ && \
  rm -Rf /tmpbuild/


RUN apt-get -y install wget
# Add postgresql client

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" > /etc/apt/sources.list.d/PostgreSQL.list'

RUN wget https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key add ACCC4CF8.asc
RUN apt-get update
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install postgresql-17

# Add AWS CLI
RUN apt-get -u install unzip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

FROM ubuntu:22.04

ENV MIRROR="mirrors.ocf.berkeley.edu"

RUN sed -i "s|deb.debian.org|$MIRROR|g" /etc/apt/sources.list \
  && apt-get update \
  && apt-get -y upgrade \
  && apt-get -y autoremove --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  bzip2 \
  ca-certificates \
  openssl \
  curl \
  libffi7 \
  libssl3 \
  libyaml-0-2 \
  libxml2 \
  libpq5 \
  libxslt1.1 \
  procps \
  zlib1g \
  libjemalloc2 \
  imagemagick \
  gnupg \
  wget \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'LC_ALL="en_US.UTF-8"' > /etc/default/locale

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main" > /etc/apt/sources.list.d/PostgreSQL.list
RUN wget https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key add ACCC4CF8.asc
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install nodejs yarn postgresql-client-17 \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ruby dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  autoconf \
  bison \
  libgdbm6 \
  libglib2.0-0 \
  libncurses6 \
  libreadline8 \
  libcurl4 \
  make \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
  echo 'install: --no-document'; \
  echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH

COPY --from=builder /usr/local /usr/local


