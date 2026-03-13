# Overview
Simpleton is a framework for bash scripts that uses the micro-scripting philosophy to orchestrate complex processes, as oppposed to using large monolithic scripts. The micro-script philosophy means that a process is broken
down into individual cells, each mapping to a folder. Each cell has it's own logging, can run in it's own process in parallel, can depend on other cells, and is designed to produce once piece of information. Cells not only
encapsulate how to obtain a piece of information, similar to how functions work in most programming languages, but they also store the actual calculated values as well, providing automatic and intrinsic caching. For example,
if 5 different steps in a process all must get a list of pods on a remote server, that cell which obtains the list of pods only needs to be executed once, and as long as that information is sufficiently fresh for the other
4 steps, they will just reuse what is already there. 

It does have similar purpose and goals as remote script execution framework like ansible, although it differs dramatically in it's implemnetation, being in my opinion dramatically easier to build, read, test, and debug than the
ansible equivalents. 

Using simpleton provides two primary advantages: 
1. It simplifies the work engineers need to do to write automation processes, since common boilerplate code managing parallelization, caching of results, dependency management, logging,
and debugging are provided by the framework, allowing code that implements the update process for most cells to be half a page or less. 
2. It greatly enhances debuggability of complex processes. Because each piece of that process is executed in a separate cell, if a workflow fails, the user can go into the specific folder of the failing cell, look at each cell
it depends on until they track down the root cause, fix that, and then resume the workflow where it left off. Cells that have already completed won't need to run again, as long as the data still meets the freshness requirements
of the operation taking place. Also since all logging data relevant to that cell is stored in the cell itself, it's much easier to get to the relevant information about why it failed. The failing cell can also be run by itself,
as many times as needed, until the problem is solved, as opposed to needing to run the whole workflow over and over which most other strategies would require. On top of these advantages, simpleton includes a built in state-of-the-art
bash debugger, which is so powerful and quick to use as to not only rival most expensive IDE debuggers other languages use, but to even be faster and more effective and getting to a root problem than most others. Using the debugger
is just a single parameter added to the commands that are already being run. The debugger provides many novel mechanisms enabling rapid narrowing down of problems that approach even omniscient debuggers in efficiency, 

Simpleton is especially valuable for dealing with management of complex computer systems, where new problems appear frequently and clever solutions must be figured out and implemented in very short periods of time. Scripting is better
for quick and short lived solutions. For longer lasting code, or code that has much higher risk and must be more carefully checked and tested, an application language is often a better solution. 

## WHat is it NOT?

Simpleton is not a replacement for a Jenkins or Github actions type devops tools. It's meant to be the orchestrator that calls tools like those. Unlike Jenkins or Github actions, simpleton scripts run locally on the users computer, so they
don't have to wait for worker nodes to become available or fight for system resources to execute a workflow. 

Simpleton is not a replacement for low level cli tools that would typically be written in C or Go. Simpleton is bash based, and anything requiring more speed or functionality would be written in a lower level language which
the bash scripts could easily call as needed. So simpleton scripts would still be calling tools like curl, kubectl, jq, etc.

Simpleton is not meant to be the source of truth of anything significant, or to provide centralized logging of its actions, or store any source of truth data. It is meant to call the tools that would perform those functions instead.
If this principle was fully applied, engineers would be able to perform all of their responsibilities without using simpleton at all. But using simpleton cells should make them be able to do those processes more effectively and efficiently. 

That doesn't mean it absolutely can't be used for any of these purposes, it's just not the main empasis behind it's design, and so the results may be less than ideal.

## Example use cases:

1. Gather pod lists and status from 100 different nodes across multiple data centers and zones into a single list, requiring ssh logins to many machines to gather the needed information.
2. Run a series of regression tests applying to dozens of docker hosts to ensure everything is behaving as expected. 
3. Go to hundreds of repos and fetch speific files and compose resulting prometheus alert configurations based on those files.
4. Log into 100 different hosts and grab uptime stats. It's true that in most cases this will be more easily seen in a dashboard which has already gathered these metrics, but there are cases where metrics are not yet available, or 
temporarily broken, or you want to double check that the metrics actually match real data, or there are nodes which can't easily transmit metrics in the standard way.

## Why BASH?

1. BASH is pretty much the king of meta-scripting. It's not at the same level nor is it meant to solve the same problems as more advanced and complete scripting languages like javascript or python. Nor can it even come close to the
performance of lower level application languages like Java, C, or Go. But it's by far the best at calling and chaining together tools writting in all of these languages, which is what most simpleton cell scripts are composed of. 
A single command line can unite input and outputs from tools written in possibly completely different languages into a seamless unit. For example:
```
cat some-file | grep -v '^#' | awk '{ print $1, $2 }' >new-file
```
The equivalent of the above command written in nearly all other languages is many, sometimes dozens, of lines of code (assuming the code is actually calling these exact external programs, allocating and mapping file descriptors,
piping those file descriptors properly, etc).

2. It's file system access is ridiculously simple and concise. Simpleton heavily relies on filesystem access and calling lots of lower level commands. 
3. It's turned out to be shockingly easy to debug, assuming the user has proper tools (provided by simpleton itself) and training.
4. Bash is well known by a large number of engineers, making the cell update scripts easy to understand to more people.
5. Bash has it's quirks, but it's been refined over such a long period of time and over so many users that the rough edges are mostly smoothed out, and what awkwardness remains has alternative approaches which work better. As a
result, it works very consistently with very few bugs. 

# Core Concepts

## Dimensions

A single cell is responsible for obtaining a single piece of information. For example, you could have a cell that contains the status of a pod in a particular datacenter, zone, and project. If you wanted status of 4 different pods,
those would be in 4 different cells. Pod name, datacenter, zone, and project in this example are dimensions of a cell. Each cell is identified by each of these dimensions set to a single value. How simpleton handles this is by
organizing cells of the same type (pod status in this case) in a tree of cells. The trunk of the tree will hold branches (each being a subfolder) for the first dimension and it's values. Those branches would further branch into
the second dimension and it's values, etc. For example, you could have a cell with a path like this: `/work/my-cells/pod-status/data_center:1/zone:a/pod:1a2b3c` Branches will always have a colon in the folder name to separate
the dimension from the member. Dimensions are a very powerful concept and in most cases just one or two dimensions can be specified, and simpleton will derive other related dimensions automatically. For example, if you know 
the exact host name you want to deploy an app to, you can specify that host name, and if the dimensions are defined well enough, the datacenter, region, zone, etc. can be derived from that host name. Or if you specified the
datacenter, region, and zone, it can derive the matching hostnames that could fit. Multiple values can be specified for dimensions to make operations that span hundreds of cells easy to execute. 

## Cell Freshness

There are two types of cells: static and dynamic. Static cells don't change their values over time. Once generated, it won't ever need to be regenerated unless one of it's dependencies were changed. For example, a cell that
takes data from an upstream dependency and compresses it will store the compressed result in it's cell, and that data won't become stale over time. A dynamic cell, on the other hand, is expected to change over time. For example,
getting a list of pods from a remote server will likely change over time. There may be one downstream cell that needs the pod list within 1 minute of freshness, and another that might only need it to within one hour of freshness.
If the cell's data isn't fresh enough for the downstream cell requiring it's value, then the cell will be updated. 

The user can also specify how fresh they want a cell to be when they update it with the `fresh` parameter. It can be set to standard time period values. Examples: fresh=1m (one minute), fresh=4d (4 days), fresh=10s (10 seconds), 
fresh=0 (refresh immediately), fresh=inf (infinite freshness, never refreshes). 

## Risk and Tolerance

Executing a cell may involve various levels of risk. Simpleton categorizes it into 4 levels: risk=0 means the cell will never impact anything significant, even if it fails, and is always safe to run. risk=1 means the cell involves
only minor risk, no real production or customer impact, only minor inconvenience if something goes wrong. risk=2 means a major failure can occur by the improper use of that cell, possibly causing significant outage in rare cases.
risk=3 means catastrophic impact can occur if this cell is not used with thorough understanding of how it works, and it's implications. Attempting to execute a cell with risk > 0 will cause simpleton to prompt the user to ensure
they have properly considered the risk, and are following all appropriate risk management procedures before running it. The `risk` parameter may be passed into an update command allowing a cell update of that risk level to proceed.

# First-time Setup and Launching

First have a folder which will contain this simpleton repo and all simpleton modules. Do not have any other repos or files in this folder (example `mkdir ~/repo; cd ~/repo; git clone https://github.com/jeremygurr/simpleton.git`)

`SIMPLETON_REPO` must be set to the path this file is in.

`SIMPLETON_HOME` is where the home folder will be mounted for the simpleton docker container. This allows
for some persistence between sessions.

`SIMPLETON_WORKSPACE` gets mounted to the work folder in the container. This should have the projects/folders you will be
running simpleton actions on. 

Ensure that the following env vars are set:

``` bash
export SIMPLETON_REPO=/path/to/this/repo
export SIMPLETON_HOME=/path/to/folder/for/persistent/home
export SIMPLETON_WORKSPACE=/path/to/workspace
```

Change directory to the simpleton repo or to any of the simpleton modules before launching the container.

Then execute the launch command.
```
./launch
```

# Running Cell Commands

Once you are inside of the simpleton container, you can execute cell
commands targettings cells in the workspace.

```
cell help         # See cell documentation
cell help status  # See cell status
cell ?            # same as cell help
cell ??           # More verbose cell help
cell ???          # Most verbose cell help
cell update ?     # See update options for current cell
cell update -?    # See update flag options
cell update dim=? # See documentation for a dimension of a cell
forge             # modify cell definitions using the forge tool
```

# Shortcuts
```
f                 # open `forge` program allowing you to see all relevant files in .dna along with upstream cells, dims and navigate to dim / derive folders to update those if needed. If you spend any time making cells, you'll be spending most your time in `forge`
update            # same as `cell update`
clean             # same as `cell clean`
```

# Navigation
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
