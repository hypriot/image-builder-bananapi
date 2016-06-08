default: build

build:
	docker build -t image-builder-bananapi .

get-cluster-lab-images:
	builder/get-cluster-lab-images.sh

sd-image: get-cluster-lab-images build
	docker run --rm --privileged -v $(shell pwd):/workspace image-builder-bananapi

shell: build
	docker run -ti --privileged -v $(shell pwd):/workspace image-builder-bananapi bash

tag:
	git tag ${TAG}
	git push origin ${TAG}
