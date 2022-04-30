docker: Dockerfile
	docker build -t simpleton --build-arg TIME_ZONE=US/Arizona .

debug: Dockerfile
	DOCKER_BUILDKIT=0 docker build --rm=false -t simpleton --build-arg TIME_ZONE=US/Arizona .

