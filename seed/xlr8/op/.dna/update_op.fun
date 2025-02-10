: ${source_paths:=src} ${target_path:=target}

lib_src=$up_chosen_path/lib-base/src

if [[ ! -d $lib_src ]]; then
  log_fatal "Missing upstream lib-base source. Should be here: $lib_src"
  fail1
fi

if [[ ! -d $cell_path/$target_path ]]; then
  mkdir $cell_path/$target_path || fail
fi

local p java_source=$lib_src:
for p in ${source_paths}; do
  java_source+="$cell_path/$p:"
done
java_source=${java_source%:}

log_and_run javac --source-path $java_source -d $cell_path/$target_path $lib_src/Main.java || fail

update_successful=t
