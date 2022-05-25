TAG_VERSION := 1.0.3
REPO := containers.renci.org/helxplatform/agent-docker

.PHONY: push
push:
	docker build . -t ${REPO}:${TAG_VERSION}
	docker tag ${REPO}:${TAG_VERSION} ${REPO}:latest
	docker push ${REPO}:${TAG_VERSION}
	docker push ${REPO}:latest
