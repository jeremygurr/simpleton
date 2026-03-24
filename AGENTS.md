# Simpleton: AI Agent Guide

## Purpose
Simpleton is a bash-based **micro-scripting framework** for orchestrating complex processes by decomposing them into **cells**—individual shell scripts organized in a tree structure with built-in caching, dependency management, and parallel execution.

## Architecture

### Core Concepts
- **Cells**: Folders in `/work/*` (active) or `/seed/*` (templates) that encapsulate a single piece of functionality
- **Dimensions**: Parameters organizing cells hierarchically (e.g., `/work/module/cell-type/region:us/zone:a/pod:abc`)
- **Cell Freshness**: Automatic staleness detection (`fresh=1m`, `fresh=0` for immediate refresh, `fresh=inf` for never)
- **Caching**: `.cyto/` folder stores runtime state; `.dna/` folder stores cell definition (templates in `/seed`, instances in `/work`)

### Execution Flow
1. User runs `cell <path> <command>` or shortcut (e.g., `update`)
2. `bin/cell` sources command metadata from `command/{name}.info`, then executes `command/{name}`
3. Commands can modify cell context (`.dna/` structure), trigger upstream updates, or run validators
4. Upstream cells recursively updated if stale; results cached for reuse

### Key Libraries (in `lib/`)
- **command-prep**: Parameter parsing (`parameters_to_env`), variable assignment operators (`+=`, `-=`, `^=`)
- **cell-lib**: Cell lifecycle, dimension resolution, upstream execution, validation flow
- **update-lib**: Cell update logic, freshness checks, pre/post validation
- **bash-lib, lifted-bash**: Function wrappers (`begin_function`/`end_function`), error handling, fork support
- **bash-debugger**: Integrated debugger with breakpoints, stack traces, variable watching
- **help-lib**: Dynamic help generation from `.info` files
- **omni-log**: Structured logging with trace/debug/verbose/info/warn/error/fatal levels

## Coding Patterns & Conventions

### Defining Commands
Commands live in `command/{name}` (executable) with metadata in `command/{name}.info`:
```bash
# command/my-command.info
name=my-command description="Does something" new_command
name=param1 default=val choices='a b c' add_parameter
command_requires_cell=t  # Requires .dna/ folder
command_modifies_context=f  # Changes .dna/ structure
```

### Cell Update Scripts
In `.dna/update_op.fun` (sourced by update command):
```bash
update_op() {
  local var1 var2  # Upstream vars auto-loaded with prefix
  log_info "Processing $var1"
  echo "$result" >result.txt  # Stored in cell root
}
```
**Key patterns**:
- Use `begin_function`/`end_function` for stack traces
- Call `fail` or `fail1` on error (automatic cleanup)
- Log with `log_info`, `log_debug`, `log_warn`, `log_fatal`
- Access upstream cell outputs via `${up_name}_var` (auto-loaded)
- Store cell output in root folder (cached indefinitely unless `fresh` expires)

### Dimension & Upstream Prep Functions
In `.dna/upstream_prep.fun` or `.dna/dim_derive.fun`:
```bash
# Called before executing upstream; can set needs_update=f to skip
my_upstream_prep() {
  if [[ condition ]]; then
    needs_update=f  # Skip this upstream
  fi
}
```

### Command Implementation
Commands source from `command/{name}` script; must define `{name}_command()`:
```bash
my_command() {
  begin_function
    local cell_path=$1  # Injected by execute_command
    # Access global: $cell_path, $path_to_commands, $seed_path
    command_successful=t
  end_function
  handle_return
}
```
**Modifying context**: Set `command_modifies_context=t` → `.dna/` files are regenerated next update.

### Adding Commands to a Cell
- **Dimensions** (branch structure): `cell dim-add dim=my_dim type=trunk_dim`
- **Upstream dependencies**: `cell up-add name=upstream_name` (links to another cell)
- **Validators**: `cell validator-add` (runs after/before update to verify success)
- **Reactors**: `cell reactor-add` (triggered on upstream changes)

## Build, Test, and Debug

### Build Docker Image
```bash
export TIME_ZONE=<Whatever time zone you're in>'  # Required
./build              # Creates simpleton image in target/
./launch             # Starts interactive container (auto-pulls git repos)
./join               # Attach to running container
```

### Testing & Debugging
- **Built-in debugger**: `cell update debug_id=123` (pause at ID), `cell update pause_at_vars=my_var` (pause on change)
- **Trace execution**: `cell update -vv` (verbose), `cell update trace_structure=t` (function entry/exit)
- **Replay**: `cell update replay=t` (re-execute even if cached)
- **Risk control**: `cell update risk_tolerance=3` (allow risky operations)
- **No formal test suite**: Cells are tested by manual execution; validation cells verify correctness

### Docker Integration
- **build** script: Compiles Dockerfile from `docker/Dockerfile` + module overlays (`*/after-Dockerfile`, `*/docker-run-options`, `*/before-docker-build` hooks)
- **Environment setup**: `.dna/` files auto-loaded on container startup via `docker/init`
- **Module discovery**: `docker/init` scans `/repo/*/seed` for module definitions and links them to `/seed/`

## Extension Points & Hooks

### Module Hooks (in module root, sourced during build)
- **before-docker-build**: Shell script sourced before Dockerfile generation
- **after-Dockerfile**: Dockerfile commands appended to image
- **docker-run-options**: Environment variables/mount options added to launch command
- **seed/**: Directory mounted as `/seed/{module_name}` in container

### Cell Hooks
- **update_op()**: Main cell computation
- **{upstream_name}_prep()**: Customize upstream behavior before execution
- **{upstream_name}_post()**: Post-process upstream output
- **validator_all_prep()**: Run before all validators
- **dim_${dim}_expand()**: Derive valid values for a dimension
- **dim_${dim}_validate()**: Check dimension value validity

### Global Parameters (from `command/all.info`)
- **Logging**: `log=trace|debug|verbose|info|warn|error|fatal`, `show_time=t`, `trace_vars=my_var`
- **Debugging**: `debug_id=123`, `pause_at_functions=func1`, `debug_on_exit=t`
- **Freshness**: `fresh=0` (immediate), `fresh=1h`, `fresh=inf` (never refresh)
- **Risk**: `risk_tolerance=low|medium|high|very_high` (controls execution safety)
- **Performance**: `grip=X` (density of debug checkpoints; lower = finer granularity)

## Safe Code Changes

### DO
- Modify cell update logic in `.dna/update_op.fun` freely (cached, easily reversible)
- Add new dimensions/upstreams with `dim-add`, `up-add` commands
- Extend commands in `command/{name}` (source pattern allows overrides)
- Use existing libraries; they follow semantic versioning within `/repo/simpleton/lib/`

### DON'T
- Modify `bin/cell` or `lib/cell-lib` without understanding full call chain (core dispatch logic)
- Edit `.cyto/` folders directly; run `clean` instead
- Commit unencrypted `.safe` files (use `safe encrypt` workflow)
- Change dimension names after cells depend on them (breaks derivation)
- Assume variables persist across forks; use explicit linking (`safe_link`)

## File Reference Map
- **Core dispatch**: `bin/cell`, `lib/command-prep`, `lib/cell-lib:execute_commands()`
- **Command system**: `command/{name}`, `command/{name}.info`, `command/all.info`
- **Cell lifecycle**: `lib/cell-lib` (50%+ of logic), `lib/update-lib`
- **Infrastructure**: `build`, `launch`, `docker/Dockerfile`, `docker/init`
- **Debugging**: `lib/bash-debugger`, `lib/lifted-bash`, access via flags (`-d`, `-vvv`)
- **Example commands**: `command/update`, `command/plant`, `command/dim-add`, `command/up-add`

## Minimal Working Example
```bash
# Create a simple cell
cd /work/my-module
mkdir -p my-cell/.dna
echo '#!/bin/bash
update_op() {
  begin_function
    echo "Hello" >output.txt
  end_function
  handle_return
}' >my-cell/.dna/update_op.fun

# Run it
cell my-cell update
# Check result
cat my-cell/output.txt  # "Hello"
```

