FROM postgres:13
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgis \
        postgresql-13-postgis-3 \
    && rm -rf /var/lib/apt/lists/*

COPY ./bin/initdb-postgis.sh /docker-entrypoint-initdb.d/
EXPOSE 5432
