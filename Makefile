.DEFAULT_GOAL :=
export
.PHONY: default
default: out/ecr-proxy/index.json

.PHONY: lint
lint:
	env -C src go vet -v ./...

.PHONY: test
test:
	env -C src go test -v ./...

out/ecr-proxy/index.json:
	docker build \
		-f Containerfile \
		--tag tkhq/ecr-proxy:latest \
		--output type=oci,tar=false,rewrite_timestamps=true,dest=out/ecr-proxy \
		.
