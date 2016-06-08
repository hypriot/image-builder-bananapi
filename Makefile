default: build

build-base:
	docker build -f Dockerfile.base -t image-builder-base .

build: build-base
	docker build -f Dockerfile.manual -t image-builder-bananapi .

sd-image: build
	docker run --rm --privileged -v $(shell pwd):/workspace image-builder-bananapi

shell: build
	docker run -ti --privileged -v $(shell pwd):/workspace image-builder-bananapi bash

tag:
	git tag ${TAG}
	git push origin ${TAG}
