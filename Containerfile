FROM stagex/busybox:sx2024.04.2@sha256:8cb9360041cd17e8df33c5cbc6c223875045c0c249254367ed7e0eb445720757 AS busybox
FROM stagex/musl:sx2024.04.2@sha256:f888fcf45fabaaae3d0268bcec902ceb94edba7bf8d09ef6966ebb20e00b7127 AS musl
FROM stagex/go:sx2024.04.2@sha256:7a0c200995e220519aae02554c082b45cc3f7452480ea45d19e15ad3ecdffb4c AS go
FROM stagex/ca-certificates:sx2024.04.2@sha256:f9fe6e67df91083fee3d88cf221f84ef77f0b67480fb5b0689e890509a712533 AS ca-certificates

FROM scratch as builder
COPY --from=busybox . /
COPY --from=musl . /
COPY --from=go . /
COPY --from=ca-certificates . /

ARG TARGETOS
ARG TARGETARCH

ENV GOPATH=/usr/home/build
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}
ENV GOPROXY=off
ENV CGO_ENABLED=0
ENV GOPROXY="https://proxy.golang.org,direct"
ENV GO_BUILDFLAGS="-x -v -trimpath -buildvcs=false"
ENV GO_LDFLAGS="-s -w -buildid= -extldflags=-static"
ENV GOFLAGS=${GO_BUILDFLAGS} -ldflags="${GO_LDFLAGS}"

RUN <<-EOF
    set -eux
    mkdir -p /newroot/etc/ssl/certs
    cp -ra --parents /etc/ssl/certs /newroot/
EOF

WORKDIR /usr/home/build/src

COPY ./src/go.mod ./src/go.sum ./
RUN go mod download

COPY ./src ./
RUN --network=none go build ${GOFLAGS} \
    -o /newroot/usr/local/bin/ecr-proxy \
    ./cmd/ecr-proxy

FROM scratch
LABEL org.opencontainers.image.source https://github.com/tkhq/ecr-proxy
COPY --from=builder /newroot /
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/ecr-proxy"]
