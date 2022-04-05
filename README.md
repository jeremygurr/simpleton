# Simpleton
light weight bash scripting elements to provide a foundation for build and maintenance systems

# Launching

`SIMPLETON_REPO` must be set to the path this file is in.

`SIMPLETON_HOME` is where the home folder will be mounted for the simpleton docker container. This allows
for some persistence between sessions.

`SIMPLETON_WORKSPACE` gets mounted to the work folder in the container. This should have the projects/folders you will be
running simpleton actions on. 


``` bash
export SIMPLETON_REPO=/path/to/this/repo
export SIMPLETON_HOME=/path/to/folder/for/persistent/home
export SIMPLETON_WORKSPACE=/path/to/workspace
./launch
```

