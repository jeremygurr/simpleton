# thin-script
light weight bash scripting elements to make sre work easier

# Launching the docker container

* Choose where you will store the persistent files on disk
```
docker run -it --rm -u `id -u` -v "$HOME/.ssh":/home/.ssh --name thin-script thin-script

