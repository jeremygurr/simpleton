: ${source_paths:=src} ${target_path:=target}

if [[ ! -d $cell_path/$target_path ]]; then
  mkdir $cell_path/$target_path || fail
fi

local p java_source=
for p in ${source_paths}; do
  java_source+=$cell_path/$p:
done

javac -d $cell_path/$target_path --source-path $cell_path/$source_paths || fail

