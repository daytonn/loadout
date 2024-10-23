#!/usr/bin/env bash

function has_program {
  local app
  app="$1"

  if [[ -z "$(which "$app")" ]]; then
    echo "no"
  else
    echo "yes"
  fi
}

function has_dir {
  local dir
  dir="$1"

  if [[ -d "$dir" ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

function has_file {
  local file
  file="$1"

  if [[ -f "$file" ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

function install {
  sudo apt update
  sudo apt install -y "$@"
}

function bootstrap {
  echo "Bootstrapping..."
  cmd sudo apt update
  cmd sudo apt upgrade -y
}

function cmd {
  echo "--> $@"
  "$@"
  echo ""
}

if [[ "$(has_program $app)" = "yes" ]]; then
  echo "has $app"
else
  echo "no $app"
fi

bootstrap
