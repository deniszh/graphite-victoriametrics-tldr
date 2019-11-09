FROM golang:alpine as builder

ENV GOPATH=/opt/go
ENV CARBONAPI_VERSION=0.12.6

RUN \
  apk update  --no-cache && \
  apk upgrade --no-cache && \
  apk add g++ git make musl-dev cairo-dev
  
WORKDIR ${GOPATH}

RUN \
  export PATH="${PATH}:${GOPATH}/bin" && \
  mkdir -p \
    /var/log/carbonapi && \
  git clone https://github.com/go-graphite/carbonapi.git

WORKDIR ${GOPATH}/carbonapi

RUN \
  export PATH="${PATH}:${GOPATH}/bin" && \
  git checkout "tags/${CARBONAPI_VERSION}" 2> /dev/null ; \
  version=${CARBONAPI_VERSION} && \
  echo "build version: ${version}" && \
  make && \
  mv carbonapi /tmp/carbonapi

FROM alpine:latest

RUN apk --no-cache add ca-certificates cairo
WORKDIR /

COPY --from=builder /tmp/carbonapi ./usr/bin/carbonapi
COPY ./carbonapi.prometheus.yaml ./etc/carbonapi.yml

CMD ["carbonapi", "-config", "/etc/carbonapi.yml"]
