# Overview

Simpleton is a framework for bash scripts that uses the micro-scripting philosophy to orchestrate
complex processes, as oppposed to using large monolithic scripts. The micro-script philosophy means
that a process is broken down into individual cells, each mapping to a folder. Each cell has it's
own logging, can run in it's own process in parallel, can depend on other cells, and is designed to
produce once piece of information. Cells not only encapsulate how to obtain a piece of information,
similar to how functions work in most programming languages, but they also store the actual
calculated values as well, providing automatic and intrinsic caching. For example, if 5 different
steps in a process all must get a list of pods on a remote server, that cell which obtains the list
of pods only needs to be executed once, and as long as that information is sufficiently fresh for
the other 4 steps, they will just reuse what is already there. 

It does have similar purpose and goals as remote script execution framework like ansible, although
it differs dramatically in it's implementation, being in dramatically easier to build, read, test,
and debug than the ansible equivalents. 

Using simpleton provides two primary advantages: 
### *First Advantage*
It simplifies the work engineers need to do to write automation processes, since common boilerplate
code managing parallelization, caching of results, dependency management, logging, and debugging are
provided by the framework, allowing code that implements the update process for most cells to be
half a page or less. 

### *Second Advantage*
It greatly enhances debuggability of complex processes. Because each piece of that process is
executed in a separate cell, if a workflow fails, the user can go into the specific folder of the
failing cell, look at each cell it depends on until they track down the root cause, fix that, and
then resume the workflow where it left off. Cells that have already completed won't need to run
again, as long as the data still meets the freshness requirements of the operation taking place.
Also since all logging data relevant to that cell is stored in the cell itself, it's much easier to
get to the relevant information about why it failed. The failing cell can also be run by itself, as
many times as needed, until the problem is solved, as opposed to needing to run the whole workflow
over and over which most other strategies would require. On top of these advantages, simpleton
includes a built in state-of-the-art bash debugger, which is so powerful and quick to use as to not
only rival most expensive IDE debuggers other languages use, but to even be faster and more
effective at getting to a root problem than most others. Using the debugger is just a single
parameter added to the commands that are already being run. The debugger provides many novel
mechanisms enabling rapid narrowing down of problems that approach even omniscient debuggers in
efficiency, 

Simpleton is especially valuable for dealing with management of complex computer systems, where new
problems appear frequently and clever solutions must be figured out and implemented in very short
periods of time. Scripting is better for quick and short lived solutions. For longer lasting code,
or code that has much higher risk and must be more carefully checked and tested, an application
language is often a better solution. 

## What it is NOT

Simpleton is not a replacement for a Jenkins or Github actions type devops tools. It's meant to be
the orchestrator that calls tools like those. Unlike Jenkins or Github actions, simpleton scripts
run locally on the users computer, so they don't have to wait for worker nodes to become available
or fight for system resources to execute a workflow. 

Simpleton is not a replacement for low level cli tools that would typically be written in C or Go.
Simpleton is bash based, and anything requiring more speed or functionality would be written in a
lower level language which the bash scripts could easily call as needed. So simpleton scripts would
still be calling tools like curl, kubectl, jq, etc.

Simpleton is not meant to be the source of truth of anything significant, or to provide centralized
logging of its actions, or store any source of truth data. It is meant to call the tools that would
perform those functions instead.  If this principle was fully applied, engineers would be able to
perform all of their responsibilities without using simpleton at all. But using simpleton cells
should make them be able to do those processes more effectively and efficiently. 

That doesn't mean it absolutely can't be used for any of these purposes, it's just not the main
empasis behind it's design, and so the results may be less than ideal.

## Example use cases:

1. Gather pod lists and status from 100 different nodes across multiple data centers and zones into
a single list, requiring ssh logins to many machines to gather the needed information.
2. Run a series of regression tests applying to dozens of docker hosts to ensure everything is
behaving as expected. 
3. Go to hundreds of repos and fetch speific files and compose resulting prometheus alert
configurations based on those files.
4. Log into 100 different hosts and grab uptime stats. It's true that in most cases this will be
more easily seen in a dashboard which has already gathered these metrics, but there are cases where
metrics are not yet available, or temporarily broken, or you want to double check that the metrics
actually match real data, or there are nodes which can't easily transmit metrics in the standard
way.

## Why BASH?

1. BASH is pretty much the king of meta-scripting. It's not at the same level nor is it meant to
solve the same problems as more advanced and complete scripting languages like javascript or python.
Nor can it even come close to the performance of lower level application languages like Java, C, or
Go. But it's by far the best at calling and chaining together tools written in all of these
languages, which is what most simpleton cell scripts are composed of.  A single command line can
unite input and outputs from tools written in possibly completely different languages into a
seamless unit. For example:

```
cat some-file | grep -v '^#' | awk '{ print $1, $2 }' >new-file
```

The equivalent of the above command written in nearly all other languages is many, sometimes dozens,
of lines of code (assuming the code is actually calling these exact external programs, allocating
and mapping file descriptors, piping those file descriptors properly, etc).

2. It's file system access is ridiculously simple and concise. Simpleton heavily relies on
filesystem access and calling lots of lower level commands. 
3. It's turned out to be shockingly easy to debug, assuming the user has proper tools (provided by
simpleton itself) and training.
4. Bash is well known by a large number of engineers, making the cell update scripts easy to
understand to more people.
5. Bash has it's quirks, but it's been refined over such a long period of time and over so many
users that the rough edges are mostly smoothed out, and what awkwardness remains has alternative
approaches which work better. As a result, it works very consistently with very few bugs. 

# Core Concepts

## Dimensions

A single cell is responsible for obtaining a single piece of information. For example, you could
have a cell that contains the status of a pod in a particular datacenter, zone, and project. If you
wanted status of 4 different pods, those would be in 4 different cells. Pod name, datacenter, zone,
and project in this example are dimensions of a cell. Each cell is identified by each of these
dimensions set to a single value. How simpleton handles this is by organizing cells of the same type
(pod status in this case) in a tree of cells. The trunk of the tree will hold branches (each being a
subfolder) for the first dimension and it's values. Those branches would further branch into the
second dimension and it's values, etc. For example, you could have a cell with a path like this:
`/work/my-cells/pod-status/data_center:1/zone:a/pod:1a2b3c` Branches will always have a colon in the
folder name to separate the dimension from the member. Dimensions are a very powerful concept and in
most cases just one or two dimensions can be specified, and simpleton will derive other related
dimensions automatically. For example, if you know the exact host name you want to deploy an app to,
you can specify that host name, and if the dimensions are defined well enough, the datacenter,
region, zone, etc. can be derived from that host name. Or if you specified the datacenter, region,
and zone, it can derive the matching hostnames that could fit. Multiple values can be specified for
dimensions to make operations that span hundreds of cells easy to execute. 

## Parameters and Environment Variables

All parameters used in the cell command can either be set as exported environment variables, or set
directly on the command line in the form of key=value. This allows a user to have a shell context
which lets them skip having to repeat parameters for each command. For example, if they are working
with in a particular zone and with a particular pod, they can set them both in the environment like
this: 

```bash
export ez=e31a pod=mypod-1234
``` 

and every cell command they run will automatically have those values set, unless they are overridden
in the individual commands. 

## Cell Freshness

There are two types of cells: static and dynamic. Static cells don't change their values over time.
Once generated, it won't ever need to be regenerated unless one of it's dependencies were changed.
For example, a cell that takes data from an upstream dependency and compresses it will store the
compressed result in it's cell, and that data won't become stale over time. A dynamic cell, on the
other hand, is expected to change over time. For example, getting a list of pods from a remote
server will likely change over time. There may be one downstream cell that needs the pod list within
1 minute of freshness, and another that might only need it to within one hour of freshness.  If the
cell's data isn't fresh enough for the downstream cell requiring it's value, then the cell will be
updated. 

The user can also specify how fresh they want a cell to be when they update it with the `fresh`
parameter. It can be set to standard time period values. Examples: fresh=1m (one minute), fresh=4d
(4 days), fresh=10s (10 seconds), fresh=0 (refresh immediately), fresh=inf (infinite freshness,
never refreshes). 

## Risk and Tolerance

Executing a cell may involve various levels of risk. Simpleton categorizes it into 4 levels: 

### risk=0

means the cell will never impact anything significant, even if it fails, and is always safe to run.

### risk=1 

means the cell involves only minor risk, no real production or customer impact, only minor
inconvenience if something goes wrong. 

### risk=2 

means a major failure can occur by the improper use of that cell, possibly causing significant
outage in rare cases.  

### risk=3 

means catastrophic impact can occur if this cell is not used with thorough understanding of how it
works, and it's implications.

Attempting to execute a cell with risk > 0 will cause simpleton to prompt the user to ensure they
have properly considered the risk, and are following all appropriate risk management procedures
before running it. The `risk` parameter may be passed into an update command allowing a cell update
of that risk level to proceed.

# First-time Setup and Launching

First have a folder which will contain this simpleton repo and all simpleton modules.  Do not have
any other repos or files in this folder (example `mkdir ~/simp-repo; cd ~/simp-repo; git clone
https://github.com/jeremygurr/simpleton.git`)

``` bash
./launch
```

# Running Cell Commands

Once you are inside of the simpleton container, you can execute cell
commands targettings cells in the workspace.

```
cell help            # See cell documentation
cell status          # See cell status
cell ?               # same as cell help
cell ??              # More verbose cell help
cell update ?        # See update options for current cell
cell update -?       # See update flag options
cell update <dim>=?  # See documentation for a dimension of a cell
```

## Shortcuts
```
update            # same as `cell update`
clean             # same as `cell clean`
```

## Viewing Logs
These are documented more thoroughly in the cell command itself. See `cell update ??` to get full details.
```
update                                     # Minimal logs
update log=verbose                         # Shows verbose logs
update -v                                  # Shortcut for verbose logs (see update -? to see a list of all flag shortcuts)
update log=debug                           # Shows debug logs
```

# Navigation
```
walk                  # use walker tool to navigate directories between cell branches and dependencies
u                     # go up to parent dir folder
uu                    # go up two folders
b                     # go back to previous folder you were in
trunk                 # will change the directory to the trunk cell of the current path
leaf                  # will go to the first leaf cell
w                     # will open the `walk` program allowing you to go directly to upstream cells and more with less keystrokes
```

# Changing Prompts
```
big_prompt            # changes the prompt to the one which gives the most info (default)
medium_prompt         # smaller prompt
small_prompt          # smallest prompt
```

# Managing Secrets Files
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

# Folder structure

## Container Level Folders

Simpleton container is divided up into the seed and the workspace. 

The seed holds the definitions of each cell. This comes from the module repo itself, and should not
change as the cells are used.  Seeds should only be changed if the cell process itself is being
modified, or new cells types are being created.

The work folder (the workspace) contains cell instances that are created based on the seed
specifications. The process of building these cells from the seeds is called `planting`, and can be
done with the `cell plant` command. 

Everything in the work folder can be deleted, and the cells could just be rebuild from the seeds.
But everything in the seed folder is permanent and should not be deleted unless you want do dispose
of cell classes permanently. 

/seed/{module}      # holds the seeds for that module
/work/{module}      # the work cells for that module
/repo/simpleton     # the main simpleton framework repo
/repo/{module}      # repos for each module

## Cell Level Folders

Each cell has the following folders:

.dna/           # linked into the seed, and is where the cell command gets the instructions for how
                # to manage this cell. Any changes to items inside of this folder changes the seed.
.cyto/          # A temporary folder which contains info about the state of the cell. If deleted it
                # will be rebuilt on the next update.

Cells may have branches into subcells, divided by a particular dimension:
<dim>:<member>/ 

example:
env:e1/
env:e2/
env:e3/

Each of those folders are also cells, which may have further branches. 
If a cell has no further branches, it is considered a leaf cell. A cell is considered a trunk cell
if it's at the top folder level of that cell type (it isn't inside of any branches).

Other than these folders, the cell update process may generate other folders and files in this cell
folder related to the cell. Sometimes there will be logs or status information, and often it will
contain an output product of some kind that the cell produced. 

# Debugging cells

## yolo mode

By default the cell commands operate in `yolo mode` which means most debug and tracing mechanisms
are bypassed. Yolo mode is enabled with `yolo=t` in the environment or on the commandline of a cell
command, and disabled with `yolo=f`. Yolo mode must be disabled to do any serious debugging, but as
a consequence, cell execution will be slower. The following instructions will not work correctly if
you have not disabled yolo.

## General Debugging Workflow

Here are the standard troubleshooting steps for almost any problem in simpleton:

Here's an example of a standard cell update debug workflow:

1.  Narrow down the scope to the exact cell that is failing.
    This can often be found by looking at the first red error message in the log that has a full cell
    path in it. This will usually be the inner most cell that was executing at the failure time.
2.  Go to the suspected cell (cd to the folder), and run an update. 
3.  Did you get the same error as before? If so go to step *7*
4.  You need to reproduce the error before debugging it, but running the update in this cell didn't
    do it. Check that you are actually in the correct cell based on the error message of the top
    level update command, and also check that you are giving the correct dimension values. If you
    don't know what dimension values the top level cell would have been passing into this one, you
    can re-run the top level cell update with this parameter `show_dims=a`, meaning it will show all
    dims being set at each level of cell that is being updated. Find the one immediately before the
    failure and you'll know what dimensions were being used. 
5.  If you still can't reproduce the error in this cell, step out one cell level. This means to find
    what cell called this cell and try to run the update from there. Easiest way to do that is to
    use the walker, and go to the downstream folder `down`, and select the downstream cell and hit
    enter. This cell was the one which directly called the failing cell. Again try and reproduce the
    problem. Continue going up the dependency chain until you find a way to reproduce the problem.
6.  At this point it is assumed that you have found a cell that you can update which reproduces the
    problem, hopefully as close to the inner most cell as possible. If that is not the case, you'll
    just have to troubleshoot the problem from the very top level update.
7.  Look in the cell for files that could give more detail as to what went wrong. Cells often store
    commands they executed or error messages into local files.
8.  Understand what that cell is doing. Run `cell ?` to learn about that cell (or just `?` or `??` 
    for the shortcut). Use the forge to look through the update operator, dimensions, and upstreams.
9.  Find out exactly when and where in the code the bug is happening. Use the Pinpointing Events
    strategies described below for details on how to do this.
10. Start the debugger immediately before the failure event. Step through and explore the code until
    you can see the source of the problem.
11. If the source of the problem is caused by a variable being set to an incorrect value, use the
    How To Find When a Variable Was Set strategy described below.

At this point you should know exactly where in the code the root of the bug is, and can apply the
fix. If you want the fix to be temporary, you can just update the .cyto/context file of the cell in
question. If you want it permanent, you'll need to edit the .dna/* file that is related, and then
commit those changes once they are tested. The process for making changes and commiting them is
described below.

## Pinpointing When an Event Happened

There are several strategies that can be used, and you'll have to experiment a bit to figure out
what is best for each scenario. 

A somewhat unique debugging mechanism provided by the bash-lifted framework is the concept of
debug_ids. Normal debug traps of stopping when a function is called or stopping at a breakpoint
within a function work well in some cases, but not others. Particularly when a function is called a
lot of times, and most of those times don't contain the condition you are looking to debug. If a
function is called 150 times, but only the 134th time has the actual bug, using a standard line
breakpoint you'd have to do a lot of stepping to get to that specific point in time where the
problem is happening. In the bash-lifted framework, it provides a thread aware debug counter called
debug_id which increments through the execution of a command. The advantage of this is you can break
at an exact point in time instead of just when a certain line or function is reached. 

### Stabilizing debug_ids

Debug ids are only useful if the debug id counter can be incremented in exactly the same pattern
every time. This requires:
1. That you can reproduce the bug consistently, which in practice is most of
the time
2. That the bug will always be reached through the same set of function calls in the same order each
time. 

Debug ids are incremented whenever the debug_id_inc function is called, which is done at the
beginning and end of each `lifted` function (the functions that start with begin_function and end
with end_function). It is also called whenever the `fence` function is called.

If the cell code is written well (small functions with the proper begin/end wrapping, and fences
where long loops might be happening), then the debug_ids can be used to get you very close to the
problem quickly. 

There is one catch here though: To avoid slowing down the script too much with the overhead of the
debug_id_inc function, bash-lifted has a `grip` mechanism built in where if a function is being
executed too rapidly, it will `slip` and skip over running the debug_id_inc, depending on how strong
the `grip` is. When debugging, you'll usually want to increase the grip significantly so that you
get consistent debug_ids. The easiest way to do this is with the `-g` flag.

Most strategies revolve around this idea: obtain a debug_id, and then the command can be given the
debug id to directly stop at that point in time like this: `cell update -vg debug=54.21.8`, and it
will execute the update until it gets to 54.21.8. Each `.` in the debug_id means the process has
forked, and are necessary to keep debug ids consistent across various forking situations.

I'll just list the strategies here in no particular order:

### Immediately entering debugger during a live command execution

If yolo is off, you can hit enter during the execution of an update command and a small menu will
appear, giving you the option to adjust log levels and enter the debugger (among other things). This
is helpful if the command seems to be running for a long time without giving any clues as to what
it's doing. Inside the debugger you can get a stack trace to see where's it's at, and can inspect
variables or step through the code. The debugger is described in more detail later.

### Increasing Logging

You can set log=verbose (or log=v or -v), or log=debug (or log=d or -d) to get a lot more
information about what's going on as a command runs. If yolo is disabled, -d will also show
debug_ids at the beginning of the line. Sometimes just using these debug_ids will get you close
enough to the problem. But if you find yourself having to step a lot and are still not seeing the
problem, then use one of the other strategies to get closer.

### Debugging at a specific function call

### Injecting the debug function directly in a script

### ADVANCED: Conditional breakpoints

### ADVANCED: Chain debugging

## How To Find When A Variable Was Set

### ADVANCED: Identifying when the state of something has changed

## Using the bash-lifted Debugger

## Common pitfalls and Gotchas

A feature exists to start a cell with more control over low-level library functions. To do this,
place a function at the top of your update_op.fun file. However, this is often something engineers
accidentally do without realizing it, and it causes crashes. To avoid this, put a # Blank Comment
line at the top so we know you are not trying to use this feature.

# Simpleton architecture

## the bin/c2 command

The file in bin/c2 is both a command and a library. It may be sourced at the top of any bash script
to provide access to the debugger and bash-lifted libraries. Or it can be executed as a standalone
command to work with simpleton cells.

The c2 file is a `packed` file. It can be split up into it's separate elements by sourcing c2 and
then running `cat c2 | unpack_scripts`. This will write the component scripts to the current
directory. They can be modified here or used separately in other scripts. They can be repacked back
into a single script with `pack_scripts >new_script_name` which will take all scripts in the current
folder (in sorted order), and create a single script out of them. Normally you would not need to do
this, but if you wanted to pull out pieces into a separate script, this is an easy way to do it. 

## bash-lifted library

Simpleton is built on top of bash-lifted, which provides substantial support for debugging bash
scripts. The bash-lifted framework (which currently exists in the bin/c2 file)

The bash-lifted framework contains the following component / features:

| feature              | description                                                          |
|----------------------|----------------------------------------------------------------------|
| ANSI constants       | for making nice looking output                                       |
| Logging              | Basic function for outputting logs according to the level            |
| Exception management | Cleanly handle failure states within scripts                         |
| Debugger             | Full featured stepping / tracing / inspecting debugger               |
| Profiler             | To determine what is slowing down a script                           |
| Tracer               | To determine where and when a variable is being set.                 |
| Reactive Autorepair  | Allows easy analysis and optional recovery of failures               |

### Loggins
### Exception Management
### Debugger

This is described in more detail later in this document.

### Profiler
### Tracer
### Reactive Autorepair

# Making new cells (or modifying existing ones)

forge                # modify cell definitions using the forge tool
f                 # open `forge` program allowing you to see all relevant files in .dna along with upstream cells, dims and navigate to dim / derive folders to update those if needed. If you spend any time making cells, you'll be spending most your time in `forge`

### Zombie commands: (All these should be caught during PR's and removed. None are meant to be permanent)
zombie_debug        # Enter Bash Debugger at this line of code
zombie_log          # Log output to shell
zombie_fence        # 


# v1 vs v2 of simpleton

The current stable version of simpleton is v1. But v2 is being actively developed on top of v1. The
bin/c2 file contains the c2 command and library, and the old v1 bin/cell command pulls heavily from
those libraries as we as libraries in lib/ to execute v1 commands. Little by little v1 commands will
be replaced with v2, and v1 cells will be replaced with v2. But in the meantime all cells should be
able to be executed with the `cell` command like normal, and they will be automatically converted
into v2 commands as they become available. Eventually the bin/c2 file will merge with bin/cell, and
the old v1 cell will be gone, as well as all the old libraries in lib/ and command definitions in
cmomands/ . 

The key improvements in v2 will be much stronger parallelization support and more exposed simpleton
framework mechanics (less of a black box). Simpleton framework itself will become simpler, while the
features it used to have (like validators and reactors) will be moved into individual cell
implementations instead of a complex global framework. The end result will be easier to debug
cells with less knowledge required of framework internals.


