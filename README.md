# Simpleton
light weight bash scripting elements to provide a foundation for build and maintenance systems


## What is simpleton?

## Core Concepts

### Cell Freshness

### Risk and Tolerance

## First-time Setup and Launching

First have a folder which will contain this simpleton repo and all simpleton modules. Do not have any other repos or files in this folder (example `mkdir ~/repo; cd ~/repo; git clone https://github.com/jeremygurr/simpleton.git`)

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
cell help         # See cell documentation
cell help status  # See cell status
cell ?            # same as cell help
cell ??           # More verbose cell help
cell ???          # Most verbose cell help
update ?          # See update options for current cell
update -?         # See update flag options
update dim=?      # See documentation for a dimension of a cell
```

## Shortcuts
```
f                 # open `forge` program allowing you to see all relevant files in .dna along with upstream cells, dims and navigate to dim / derive folders to update those if needed. If you spend any time making cells, you'll be spending most your time in `forge`
```

### Navigation
```
u                 # go up to parent dir folder
uu                # go up two folders
b                 # go back to previous folder you were in
trunk                 # will change the directory to the trunk cell of the current path
leaf {dim member}...  # will go to the specified leaf cell
leaf                  # will go to the first leaf cell
w                     # will open the `walk` program allowing you to go directly to upstream cells and more with less keystrokes
```

### Changing Prompts
```
big_prompt            # changes the prompt to the one which gives the most info (default)
medium_prompt         # smaller prompt
small_prompt          # smallest prompt
```

## Viewing Logs
update                                     # Minimal logs
update -v                                  # Shows verbose logs created with log_info
update -d                                  # Shows more logs created with log_debug
update trace_var=some_var                  # Shows you how a variable or dimension is altered during the execution of a cell update
update debug_watch='some_var some_var2'    # 

### While executing a cell command
hit <enter> to pause any cell. From here you can change log_level, go into debug mode and hit <enter> again to resume when ready
These useful variables become available: (see more with debugger and checking `declare -p` or `declare -f`)
```
cell_path           # Path to current cell
up_path             # Path to upstream folder of current cell
trunk_cell          # Path to cell trunk
```
These useful commands become available through the simpleton library:
```
log_info
log_debug
log_fatal
fail
fail1
fail2
zombie_*            # see `Zombie commands` section below
```

### Clean commands & Fresh variables
```
Commands you can run within any cell:
clean ?      # See documentation for clean commands
clean0       # Only clean the runtime files in .cyto folder but keep the status of the cell and upstream freshness intact
clean        # Wipe out the entire cell cached files and folders
clean-all    # Wipes out the cached files and folders of all cells in the current module (except for clean-resistant cells)

Variables / files to define in a cell or use in the code logic:
fresh                      # How long this cell should stay fresh after update (i.e 1d 3h 5m etc.)
default_freshness.var      # .dna file which specifies how long this cell should stay fresh by default 
clean_resistant.var        # .dna file which says 't' if this cell should be skipped during `clean-all`
top_fresh                  # Freshness from the top-level cell which caused this cell to eventually be run
```

### Risk variables / files
```
risk                    # Levels 1-3. 3 is High risk. 0 is no risk
risk_tolerance          # How high of a risk level to prevent stop and ask user to confirm if they want to proceed
```

### After cell command has completed
.cyto folder is created which caches cell runtime information including functions and variables

### Zombie commands: (All these should be caught during PR's and removed. None are meant to be permanent)
zombie_debug        # Enter Bash Debugger at this line of code
zombie_log          # Log output to shell
zombie_fence        # 
zombie_pause        #
zombie_lap_reset    #

### SSH
attach              # Lets you ssh directly to a host that a cell recently used ssh for

## Managing Secrets Files
Process to add or update secrets:
 * create or clone a new cell with the new secrets name:
   `cd /work/some-module/secrets/secrets-cell; new clone /work/some-module/secrets/new-secret-cell-name`
 * Create the encrypted secret in seed
   `seed; vim new-secret.var`
 * Encrypt the file:
   `safe encrypt from_file=new-secret.var`
 * Delete the unencrypted file:
   `rm new-secret.var`
 * Go back to work and run 'update'
   `work; update`
 * You should now see the unencrypted file in your cell output
 __IMPORTANT: Make sure before you raise your PR for a module, you do a `git status` to check to make sure you are not committing any unencrypted secrets file. This is to be sure you removed it properly

Process to update existing secret:
 * Decrypt and edit the decrypted file then follow same process as above to re-encrypt and remove the unencrypted form
 `safe decrypt from_file=filename.safe`

## Hide Secrets in logs or command output
Create the dimension name in /seed/.dim/ folder (example ssh_root_pass)
Create is_secret.var file inside the dimension and make it contain `t`. (example: cat t >/seed/.dim/ssh_root_pass/is_secret.var) 
   Then anywhere you are using the secret variable, you can source the lib file which has hide_secrets command:
   ```
   source $SIMPLETON_LIB/omni-log # or source $SIMPLETON_LIB/lifted_bash2
   local docker_command="docker run -it -e 'ssh_root_pass=$ssh_root_pass' my_container"
   local filtered_docker_command=$docker_command
   
   # If you want to use the secret in a docker run command for example, and want to output the results to the terminal but still hide the ssh_root_pass do this:
   hide_secrets filtered_docker_command
   eval docker_command
   log_info "$filtered_docker_command" >/tmp/logs.out
   ```

## How Parallel Processing Works

## Using the Debugger

## Multiple Choice

## Common pitfalls and Gotchas
A feature exists to start a cell with more control over low-level library functions. To do this, place a function at the top of your update_op.fun file. However, this is often something engineers accidentally do without realizing it, and it causes crashes. To avoid this, put a # Blank Comment line at the top so we know you are not trying to use this feature.
