FROM python:3.9-slim-buster as base

FROM base as builder
RUN apt-get update && apt-get install -y git

# there are no wheels for some packages (geventhttpclient?) for arm64/aarch64, so we need some build dependencies there
RUN if [ -n "$(arch | grep 'arm64\|aarch64')" ]; then apt install -y --no-install-recommends gcc python3-dev; fi

RUN if [ -n "$(arch | grep 'arm64')" ]; then \
     DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gnupg wget software-properties-common lsb-release make libsasl2-modules-gssapi-mit krb5-user && \
    wget -qO - https://packages.confluent.io/deb/7.1/archive.key | apt-key add - && add-apt-repository "deb [arch=arm64] https://packages.confluent.io/deb/7.1 stable main" && add-apt-repository "deb https://packages.confluent.io/clients/deb $(lsb_release -cs) main" && \
     apt-get update && \
     apt-get install -y librdkafka-dev ;fi

RUN mkdir librdkafka
RUN if [ -n "$(arch | grep 'aarch64')" ]; then apt-get -y install make libssl-dev zlib1g-dev g++ && git clone https://github.com/edenhill/librdkafka; fi
WORKDIR /librdkafka
RUN if [ -n "$(arch | grep 'aarch64')" ]; then ./configure --prefix=/usr && make && make install ; fi

WORKDIR /

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY . /build
RUN pip install /build/
RUN pip install locust-plugins
#
FROM base
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
# turn off python output buffering
ENV PYTHONUNBUFFERED=1
RUN useradd --create-home locust
# ensure correct permissions
RUN chown -R locust /opt/venv
USER locust
WORKDIR /home/locust
EXPOSE 8089 5557
ENTRYPOINT ["locust"]
#
