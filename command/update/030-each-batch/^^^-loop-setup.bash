#!/bin/bash

handle_step_each() {
  leaf_function=execute_command_step_plain_folder for_each_batch "${batch_dims[@]}"
}
