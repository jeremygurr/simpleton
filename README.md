# Simpleton
light weight bash scripting elements to provide a foundation for build and maintenance systems

## Launching

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

## Running

Once you are inside of the simpleton container, you can execute cell
commands targettings cells in the workspace.

```
cell help         # will list commands that can be executed
cell status help  # get details about how to use a command
```

## Update Phases

Cell updates have three phases: context, dependency, and execution. 

### Context phase

### Dependency Phase

### Execution Phase

## Caching Information

## Viewing Logs

## Handlers

## Archetypes

## Extensions

## Managing Secret Files

## How Parallel Processing Works

## Managing Locks

## Using the Debugger

## Vector vs Scalar Cells

### Dimensions and Measures

## Multiple Choice

## Multi Level Aggregation

