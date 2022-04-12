docker: Dockerfile
	docker build -t simpleton .

debug: Dockerfile
	DOCKER_BUILDKIT=0 docker build --rm=false -t simpleton .

