TAG_VERSION := v0.0.16

.PHONY: push
push:
	docker build . -t helxplatform/agent-docker:${TAG_VERSION}
	docker tag helxplatform/agent-docker:${TAG_VERSION} helxplatform/agent-docker:latest
	docker push helxplatform/agent-docker:${TAG_VERSION}
	docker push helxplatform/agent-docker:latest
