FROM ubuntu:16.04

ENV PGPOOL2_VERSION 3.7.1
ENV POSTGRESQL_VERSION 9.6

ENV LANG C.UTF-8

#  Timezone
#-----------------------------------------------
ENV TIMEZONE Asia/Tokyo

RUN ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

#  Library
#-----------------------------------------------
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
        curl \
        wget \
		ca-certificates \
        memcached \
	&& rm -rf /var/lib/apt/lists/*

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" >> /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install  -y --no-install-recommends  \
        postgresql-client-${POSTGRESQL_VERSION} \
        libpq-dev \
        postgresql-server-dev-${POSTGRESQL_VERSION} \
	&& rm -rf /var/lib/apt/lists/*

#  Download pgpool2
#-----------------------------------------------
RUN curl -L -o pgpool-II-${PGPOOL2_VERSION}.tar.gz http://www.pgpool.net/download.php?f=pgpool-II-${PGPOOL2_VERSION}.tar.gz \
    && tar zxvf pgpool-II-${PGPOOL2_VERSION}.tar.gz

#  Build pgpool2
#-----------------------------------------------
WORKDIR /pgpool-II-${PGPOOL2_VERSION}
RUN buildDeps=' \
      make \
      g++ \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && ./configure \
    && make \
    && make install \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /var/lib/apt/lists/*

#  Build pgpool2 extensions for postgres
#-----------------------------------------------
WORKDIR /pgpool-II-${PGPOOL2_VERSION}/src/sql
RUN buildDeps=' \
      make \
      g++ \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && make \
    && make install \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /var/lib/apt/lists/*

RUN ldconfig

# Clean up files
#-----------------------------------------------
RUN rm -rf /pgpool-II-${PGPOOL2_VERSION} & rm /pgpool-II-${PGPOOL2_VERSION}.tar.gz

# Expose pgpool port
#-----------------------------------------------
EXPOSE 9999

# Set up template of configuartion files
#-----------------------------------------------
RUN cp /usr/local/etc/pcp.conf.sample /usr/local/etc/pcp.conf
RUN cp /usr/local/etc/pgpool.conf.sample /usr/local/etc/pgpool.conf
RUN cp /usr/local/etc/pool_hba.conf.sample /usr/local/etc/pool_hba.conf

ENTRYPOINT ["pgpool"]
CMD ["-n"]
