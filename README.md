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

## Running Cell Commands

Once you are inside of the simpleton container, you can execute cell
commands targettings cells in the workspace.

```
cell help         # will list commands that can be executed
cell help status  # get details about how to use a command
```

## Shortcuts

### Navigation
```
trunk                 # will change the directory to the trunk cell of the current path
leaf {dim member}...  # will go to the specified leaf cell
leaf                  # will go to the first leaf cell
```

### Changing Prompts
```
big_prompt            # changes the prompt to the one which gives the most info (default)
medium_prompt         # smaller prompt
small_prompt          # smallest prompt
```

## Viewing Logs

### While executing a cell command

### After cell command has completed

## Managing Secret Files

## How Parallel Processing Works

## Using the Debugger

## Multiple Choice

